with Ada.Strings.Fixed;
with Ada.Unchecked_Deallocation;

package body Aion.Reactor_Backend is
   use type Aion.IO_Resource.Native_Handle;
   use type Aion.IO_Token.IO_Token;
   use type Aion.Types.Resource_State;

   procedure Free_State is new Ada.Unchecked_Deallocation
     (Backend_State, Backend_State_Access);
   procedure Free_Backend is new Ada.Unchecked_Deallocation
     (Backend, Backend_Access);

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function Natural_Image (Value : Natural) return String is
   begin
      return Trim (Natural'Image (Value));
   end Natural_Image;

   protected body Backend_State is
      procedure Register
        (Token    : in Aion.IO_Token.IO_Token;
         Handle   : in Aion.IO_Resource.Native_Handle;
         Interest : in Aion.Readiness.Readiness_Set;
         Waker    : in Aion.Waker.Waker;
         Accepted : out Boolean;
         Failure  : out Aion.Errors.Error) is
         Slot : Natural := 0;
      begin
         Accepted := False;
         Failure := Aion.Errors.Ok;

         if Stop_Requested then
            Failure := Aion.Errors.Make
              (Aion.Errors.Resource_Closed,
               "reactor backend is stopping",
               "Aion.Reactor_Backend.Register");
            return;
         end if;

         if not Aion.IO_Token.Is_Valid (Token) then
            Failure := Aion.Errors.Make
              (Aion.Errors.Invalid_Argument,
               "registration requires a valid IO token",
               "Aion.Reactor_Backend.Register");
            return;
         end if;

         if Handle = Aion.IO_Resource.Invalid_Native_Handle then
            Failure := Aion.Errors.Make
              (Aion.Errors.Invalid_Argument,
               "registration requires a valid native handle placeholder",
               "Aion.Reactor_Backend.Register");
            return;
         end if;

         if not Aion.Readiness.Any (Interest) then
            Failure := Aion.Errors.Make
              (Aion.Errors.Invalid_Argument,
               "registration requires at least one readiness interest",
               "Aion.Reactor_Backend.Register");
            return;
         end if;

         for Index in Resources'Range loop
            if Resources (Index).State /= Aion.Types.Resource_Closed and then
               Resources (Index).Token = Token
            then
               Failure := Aion.Errors.Make
                 (Aion.Errors.Invalid_State,
                  "IO token is already registered",
                  "Aion.Reactor_Backend.Register");
               return;
            end if;

            if Slot = 0 and then Resources (Index).State = Aion.Types.Resource_Closed then
               Slot := Index;
            end if;
         end loop;

         if Slot = 0 or else Resource_Count_Value >= Max_Resources then
            Failure := Aion.Errors.Make
              (Aion.Errors.Capacity_Exceeded,
               "reactor backend resource registry is full",
               "Aion.Reactor_Backend.Register");
            return;
         end if;

         Resources (Slot) :=
           (Token    => Token,
            Handle   => Handle,
            Interest => Interest,
            Waker    => Waker,
            State    => Aion.Types.Resource_Open);
         Resource_Count_Value := Resource_Count_Value + 1;
         Registered_Total := Registered_Total + 1;
         Accepted := True;
      end Register;

      procedure Unregister
        (Token   : in Aion.IO_Token.IO_Token;
         Removed : out Boolean) is
      begin
         Removed := False;

         for Index in Resources'Range loop
            if Resources (Index).State /= Aion.Types.Resource_Closed and then
               Resources (Index).Token = Token
            then
               Resources (Index) := Null_Registration;

               if Resource_Count_Value > 0 then
                  Resource_Count_Value := Resource_Count_Value - 1;
               end if;

               Unregistered_Total := Unregistered_Total + 1;
               Removed := True;
               return;
            end if;
         end loop;
      end Unregister;

      procedure Update_Interest
        (Token    : in Aion.IO_Token.IO_Token;
         Interest : in Aion.Readiness.Readiness_Set;
         Updated  : out Boolean) is
      begin
         Updated := False;

         if not Aion.Readiness.Any (Interest) then
            return;
         end if;

         for Index in Resources'Range loop
            if Resources (Index).State = Aion.Types.Resource_Open and then
               Resources (Index).Token = Token
            then
               Resources (Index).Interest := Interest;
               Interest_Updates := Interest_Updates + 1;
               Updated := True;
               return;
            end if;
         end loop;
      end Update_Interest;

      procedure Notify_Readiness
        (Token    : in Aion.IO_Token.IO_Token;
         Ready    : in Aion.Readiness.Readiness_Set;
         Accepted : out Boolean;
         Failure  : out Aion.Errors.Error) is
         Matched : Natural := 0;
      begin
         Accepted := False;
         Failure := Aion.Errors.Ok;

         if Stop_Requested then
            Failure := Aion.Errors.Make
              (Aion.Errors.Resource_Closed,
               "reactor backend is stopping",
               "Aion.Reactor_Backend.Notify_Readiness");
            return;
         end if;

         if not Aion.Readiness.Any (Ready) then
            Failure := Aion.Errors.Make
              (Aion.Errors.Invalid_Argument,
               "readiness notification must contain at least one flag",
               "Aion.Reactor_Backend.Notify_Readiness");
            return;
         end if;

         for Index in Resources'Range loop
            if Resources (Index).State = Aion.Types.Resource_Open and then
               Resources (Index).Token = Token
            then
               Matched := Index;
               exit;
            end if;
         end loop;

         if Matched = 0 then
            Failure := Aion.Errors.Make
              (Aion.Errors.Invalid_State,
               "readiness notification token is not registered",
               "Aion.Reactor_Backend.Notify_Readiness");
            return;
         end if;

         if not Aion.Readiness.Matches (Ready, Resources (Matched).Interest) then
            Accepted := True;
            return;
         end if;

         if Event_Count >= Max_Events then
            Readiness_Dropped := Readiness_Dropped + 1;
            Failure := Aion.Errors.Make
              (Aion.Errors.Capacity_Exceeded,
               "reactor backend event queue is full",
               "Aion.Reactor_Backend.Notify_Readiness");
            return;
         end if;

         Events (Event_Tail) :=
           (Token => Token,
            Ready => Aion.Readiness.Intersect (Ready, Resources (Matched).Interest),
            Waker => Resources (Matched).Waker);

         if Event_Tail = Max_Events then
            Event_Tail := 1;
         else
            Event_Tail := Event_Tail + 1;
         end if;

         Event_Count := Event_Count + 1;
         Readiness_Queued := Readiness_Queued + 1;
         Accepted := True;
      end Notify_Readiness;

      entry Wait
        (Event : out Backend_Event;
         Found : out Boolean)
        when Event_Count > 0 or else Stop_Requested is
      begin
         if Event_Count = 0 then
            Event := Null_Event;
            Found := False;
            return;
         end if;

         Event := Events (Event_Head);
         Events (Event_Head) := Null_Event;

         if Event_Head = Max_Events then
            Event_Head := 1;
         else
            Event_Head := Event_Head + 1;
         end if;

         Event_Count := Event_Count - 1;
         Found := True;
      end Wait;

      procedure Request_Stop is
      begin
         Stop_Requested := True;
      end Request_Stop;

      procedure Mark_Worker_Started is
      begin
         Worker_Started := True;
         Worker_Stopped := False;
      end Mark_Worker_Started;

      procedure Mark_Worker_Stopped is
      begin
         Worker_Stopped := True;
      end Mark_Worker_Stopped;

      procedure Mark_Dispatched is
      begin
         Readiness_Dispatched := Readiness_Dispatched + 1;
      end Mark_Dispatched;

      function Snapshot return Backend_Stats is
      begin
         return
           (Backend              => Aion.Platform.Default_Backend,
            Max_Resources        => Max_Resources,
            Registered_Resources => Resource_Count_Value,
            Event_Depth          => Event_Count,
            Event_Capacity       => Max_Events,
            Registered_Total     => Registered_Total,
            Unregistered_Total   => Unregistered_Total,
            Interest_Updates     => Interest_Updates,
            Readiness_Queued     => Readiness_Queued,
            Readiness_Dispatched => Readiness_Dispatched,
            Readiness_Dropped    => Readiness_Dropped,
            Worker_Running       => Worker_Started and then not Worker_Stopped,
            Stop_Requested       => Stop_Requested);
      end Snapshot;

      function Resource_Count return Natural is
      begin
         return Resource_Count_Value;
      end Resource_Count;

      function Event_Depth return Natural is
      begin
         return Event_Count;
      end Event_Depth;

      function Stopping return Boolean is
      begin
         return Stop_Requested;
      end Stopping;
   end Backend_State;

   function Create
     (Max_Resources : Positive;
      Max_Events    : Positive;
      Kind          : Aion.Platform.Backend_Kind := Aion.Platform.Default_Backend)
      return Backend_Access is
   begin
      return new Backend'
        (Kind  => Kind,
         State => new Backend_State
           (Max_Resources => Max_Resources,
            Max_Events    => Max_Events));
   end Create;

   procedure Destroy (Item : in out Backend_Access) is
   begin
      if Item = null then
         return;
      end if;

      if Item.State /= null then
         Item.State.Request_Stop;
         Free_State (Item.State);
      end if;

      Free_Backend (Item);
   end Destroy;

   function Register
     (Item     : not null Backend_Access;
      Token    : Aion.IO_Token.IO_Token;
      Handle   : Aion.IO_Resource.Native_Handle;
      Interest : Aion.Readiness.Readiness_Set;
      Waker    : Aion.Waker.Waker) return Operation_Results.Result_Type is
      Accepted : Boolean := False;
      Failure  : Aion.Errors.Error := Aion.Errors.Ok;
   begin
      if Item.State = null then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "reactor backend was not initialized",
            "Aion.Reactor_Backend.Register");
      end if;

      Item.State.Register (Token, Handle, Interest, Waker, Accepted, Failure);

      if Accepted then
         return Operation_Results.Success (True);
      end if;

      return Operation_Results.Failure (Failure);
   end Register;

   function Unregister
     (Item  : not null Backend_Access;
      Token : Aion.IO_Token.IO_Token) return Operation_Results.Result_Type is
      Removed : Boolean := False;
   begin
      if Item.State = null then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "reactor backend was not initialized",
            "Aion.Reactor_Backend.Unregister");
      end if;

      Item.State.Unregister (Token, Removed);

      if Removed then
         return Operation_Results.Success (True);
      end if;

      return Operation_Results.Failure
        (Aion.Errors.Invalid_State,
         "IO token is not registered",
         "Aion.Reactor_Backend.Unregister");
   end Unregister;

   function Update_Interest
     (Item     : not null Backend_Access;
      Token    : Aion.IO_Token.IO_Token;
      Interest : Aion.Readiness.Readiness_Set) return Operation_Results.Result_Type is
      Updated : Boolean := False;
   begin
      if Item.State = null then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "reactor backend was not initialized",
            "Aion.Reactor_Backend.Update_Interest");
      end if;

      Item.State.Update_Interest (Token, Interest, Updated);

      if Updated then
         return Operation_Results.Success (True);
      end if;

      return Operation_Results.Failure
        (Aion.Errors.Invalid_State,
         "IO token is not registered or interest is empty",
         "Aion.Reactor_Backend.Update_Interest");
   end Update_Interest;

   function Notify_Readiness
     (Item  : not null Backend_Access;
      Token : Aion.IO_Token.IO_Token;
      Ready : Aion.Readiness.Readiness_Set) return Operation_Results.Result_Type is
      Accepted : Boolean := False;
      Failure  : Aion.Errors.Error := Aion.Errors.Ok;
   begin
      if Item.State = null then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "reactor backend was not initialized",
            "Aion.Reactor_Backend.Notify_Readiness");
      end if;

      Item.State.Notify_Readiness (Token, Ready, Accepted, Failure);

      if Accepted then
         return Operation_Results.Success (True);
      end if;

      return Operation_Results.Failure (Failure);
   end Notify_Readiness;

   procedure Wait
     (Item  : in out Backend;
      Event : out Backend_Event;
      Found : out Boolean) is
   begin
      if Item.State = null then
         Event := Null_Event;
         Found := False;
         return;
      end if;

      Item.State.Wait (Event, Found);
   end Wait;

   procedure Request_Stop (Item : in out Backend) is
   begin
      if Item.State /= null then
         Item.State.Request_Stop;
      end if;
   end Request_Stop;

   procedure Mark_Worker_Started (Item : in out Backend) is
   begin
      if Item.State /= null then
         Item.State.Mark_Worker_Started;
      end if;
   end Mark_Worker_Started;

   procedure Mark_Worker_Stopped (Item : in out Backend) is
   begin
      if Item.State /= null then
         Item.State.Mark_Worker_Stopped;
      end if;
   end Mark_Worker_Stopped;

   procedure Mark_Dispatched (Item : in out Backend) is
   begin
      if Item.State /= null then
         Item.State.Mark_Dispatched;
      end if;
   end Mark_Dispatched;

   function Stats_Of (Item : Backend) return Backend_Stats is
      Snapshot : Backend_Stats;
   begin
      if Item.State = null then
         return Backend_Stats'(others => <>);
      end if;

      Snapshot := Item.State.Snapshot;
      Snapshot.Backend := Item.Kind;
      return Snapshot;
   end Stats_Of;

   function Resource_Count_Of (Item : Backend) return Natural is
   begin
      if Item.State = null then
         return 0;
      end if;

      return Item.State.Resource_Count;
   end Resource_Count_Of;

   function Event_Depth_Of (Item : Backend) return Natural is
   begin
      if Item.State = null then
         return 0;
      end if;

      return Item.State.Event_Depth;
   end Event_Depth_Of;

   function Is_Stopping (Item : Backend) return Boolean is
   begin
      return Item.State = null or else Item.State.Stopping;
   end Is_Stopping;

   function Image (Event : Backend_Event) return String is
   begin
      if not Aion.IO_Token.Is_Valid (Event.Token) then
         return "Backend_Event(null)";
      end if;

      return
        "Backend_Event(token=" & Aion.IO_Token.Image (Event.Token) &
        ", ready=" & Aion.Readiness.Image (Event.Ready) & ")";
   end Image;

   function Image (Stats : Backend_Stats) return String is
   begin
      return
        "Backend_Stats(backend=" & Aion.Platform.Image (Stats.Backend) &
        ", max_resources=" & Natural_Image (Stats.Max_Resources) &
        ", registered=" & Natural_Image (Stats.Registered_Resources) &
        ", event_depth=" & Natural_Image (Stats.Event_Depth) &
        ", event_capacity=" & Natural_Image (Stats.Event_Capacity) &
        ", registered_total=" & Natural_Image (Stats.Registered_Total) &
        ", unregistered_total=" & Natural_Image (Stats.Unregistered_Total) &
        ", interest_updates=" & Natural_Image (Stats.Interest_Updates) &
        ", queued=" & Natural_Image (Stats.Readiness_Queued) &
        ", dispatched=" & Natural_Image (Stats.Readiness_Dispatched) &
        ", dropped=" & Natural_Image (Stats.Readiness_Dropped) &
        ", worker_running=" & Boolean'Image (Stats.Worker_Running) &
        ", stopping=" & Boolean'Image (Stats.Stop_Requested) & ")";
   end Image;

end Aion.Reactor_Backend;
