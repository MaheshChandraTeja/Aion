with Ada.Strings.Fixed;
with Ada.Unchecked_Deallocation;
with Aion.Errors;

package body Aion.Timer_Queue is
   use type Aion.Clock.Instant;

   procedure Free_Service is new Ada.Unchecked_Deallocation
     (Object => Timer_Service,
      Name   => Timer_Service_Access);

   procedure Free_Registry is new Ada.Unchecked_Deallocation
     (Object => Timer_Registry,
      Name   => Timer_Registry_Access);

   procedure Free_Worker is new Ada.Unchecked_Deallocation
     (Object => Timer_Worker,
      Name   => Timer_Worker_Access);

   protected Id_Source is
      procedure Next (Id : out Timer_Id);
   private
      Current : Timer_Id := 1;
   end Id_Source;

   protected body Id_Source is
      procedure Next (Id : out Timer_Id) is
      begin
         Id := Current;

         if Current = Timer_Id'Last then
            Current := 1;
         else
            Current := Current + 1;
         end if;
      end Next;
   end Id_Source;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function Natural_Image (Value : Natural) return String is
   begin
      return Trim (Natural'Image (Value));
   end Natural_Image;

   function Boolean_Image (Value : Boolean) return String is
   begin
      if Value then
         return "true";
      else
         return "false";
      end if;
   end Boolean_Image;

   function Timer_Id_Image (Value : Timer_Id) return String is
   begin
      return Trim (Timer_Id'Image (Value));
   end Timer_Id_Image;

   procedure Complete_Record (Item : Timer_Record) is
      Ignored : Timer_Promises.Operation_Results.Result_Type :=
        Timer_Promises.Complete (Item.Promise, True);
      pragma Unreferenced (Ignored);
   begin
      null;
   end Complete_Record;

   procedure Cancel_Record
     (Item   : Timer_Record;
      Reason : String := "timer cancelled") is
      Ignored : Timer_Promises.Operation_Results.Result_Type :=
        Timer_Promises.Cancel (Item.Promise, Reason);
      pragma Unreferenced (Ignored);
   begin
      null;
   end Cancel_Record;

   protected body Timer_Registry is
      procedure Swap (Left, Right : Positive) is
         Tmp : Timer_Record := Heap (Left);
      begin
         Heap (Left) := Heap (Right);
         Heap (Right) := Tmp;
      end Swap;

      procedure Bubble_Up (Index : Positive) is
         Current : Positive := Index;
         Parent  : Positive;
      begin
         while Current > 1 loop
            Parent := Current / 2;
            exit when Heap (Parent).Deadline <= Heap (Current).Deadline;

            Swap (Parent, Current);
            Current := Parent;
         end loop;
      end Bubble_Up;

      procedure Bubble_Down (Index : Positive) is
         Current  : Positive := Index;
         Left     : Positive;
         Right    : Positive;
         Smallest : Positive;
      begin
         loop
            Left := Current * 2;
            Right := Left + 1;
            Smallest := Current;

            if Left <= Count and then Heap (Left).Deadline < Heap (Smallest).Deadline then
               Smallest := Left;
            end if;

            if Right <= Count and then Heap (Right).Deadline < Heap (Smallest).Deadline then
               Smallest := Right;
            end if;

            exit when Smallest = Current;

            Swap (Current, Smallest);
            Current := Smallest;
         end loop;
      end Bubble_Down;

      procedure Remove_At
        (Index : Positive;
         Item  : out Timer_Record) is
      begin
         Item := Heap (Index);

         if Index = Count then
            Heap (Count) := Null_Record;
            Count := Count - 1;
            return;
         end if;

         Heap (Index) := Heap (Count);
         Heap (Count) := Null_Record;
         Count := Count - 1;

         if Count > 0 then
            if Index > 1 and then Heap (Index).Deadline < Heap (Index / 2).Deadline then
               Bubble_Up (Index);
            else
               Bubble_Down (Index);
            end if;
         end if;
      end Remove_At;

      procedure Insert
        (Item     : in Timer_Record;
         Accepted : out Boolean) is
      begin
         if Stop_Requested or else Count >= Max_Capacity then
            Rejected_Total := Rejected_Total + 1;
            Accepted := False;
            return;
         end if;

         Count := Count + 1;
         Heap (Count) := Item;
         Bubble_Up (Count);
         Scheduled_Total := Scheduled_Total + 1;
         Accepted := True;
      end Insert;

      procedure Cancel
        (Id    : in Timer_Id;
         Item  : out Timer_Record;
         Found : out Boolean) is
      begin
         Item := Null_Record;
         Found := False;

         if Id = No_Timer then
            return;
         end if;

         for Index in 1 .. Count loop
            if Heap (Index).Id = Id then
               Remove_At (Index, Item);
               Cancelled_Total := Cancelled_Total + 1;
               Found := True;
               return;
            end if;
         end loop;
      end Cancel;

      procedure Pop_Due
        (Now   : in Aion.Clock.Instant;
         Item  : out Timer_Record;
         Found : out Boolean) is
      begin
         Item := Null_Record;
         Found := False;

         if Count = 0 then
            return;
         end if;

         if Heap (1).Deadline <= Now then
            Remove_At (1, Item);
            Fired_Total := Fired_Total + 1;
            Found := True;
         end if;
      end Pop_Due;

      procedure Pop_Any
        (Item  : out Timer_Record;
         Found : out Boolean) is
      begin
         Item := Null_Record;
         Found := False;

         if Count > 0 then
            Remove_At (1, Item);
            Cancelled_Total := Cancelled_Total + 1;
            Found := True;
         end if;
      end Pop_Any;

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

      function Next_Wait return Duration is
         Raw : Duration;
      begin
         if Stop_Requested then
            return 0.0;
         elsif Count = 0 then
            return 0.010;
         else
            Raw := Aion.Clock.Time_Until (Heap (1).Deadline);

            if Raw <= 0.0 then
               return 0.0;
            elsif Raw > 0.050 then
               return 0.050;
            else
               return Raw;
            end if;
         end if;
      end Next_Wait;

      function Depth return Natural is
      begin
         return Count;
      end Depth;

      function Capacity return Natural is
      begin
         return Max_Capacity;
      end Capacity;

      function Stopping return Boolean is
      begin
         return Stop_Requested;
      end Stopping;

      function Worker_Running return Boolean is
      begin
         return Worker_Started and then not Worker_Stopped;
      end Worker_Running;

      function Snapshot return Timer_Stats is
      begin
         return Timer_Stats'
           (Capacity        => Max_Capacity,
            Pending         => Count,
            Scheduled_Total => Scheduled_Total,
            Fired_Total     => Fired_Total,
            Cancelled_Total => Cancelled_Total,
            Rejected_Total  => Rejected_Total,
            Worker_Running  => Worker_Running,
            Stop_Requested  => Stop_Requested);
      end Snapshot;
   end Timer_Registry;

   task body Timer_Worker is
      Item  : Timer_Record := Null_Record;
      Found : Boolean := False;
   begin
      Registry.Mark_Worker_Started;

      loop
         Registry.Pop_Due (Aion.Clock.Now, Item, Found);

         if Found then
            Complete_Record (Item);
         elsif Registry.Stopping then
            exit;
         else
            delay Registry.Next_Wait;
         end if;
      end loop;

      loop
         Registry.Pop_Any (Item, Found);
         exit when not Found;
         Cancel_Record (Item, "timer service stopped before deadline");
      end loop;

      Registry.Mark_Worker_Stopped;
   exception
      when others =>
         Registry.Mark_Worker_Stopped;
   end Timer_Worker;

   function Create_Service
     (Capacity : Positive := Default_Timer_Capacity) return Timer_Service_Access is
      Service : Timer_Service_Access := new Timer_Service;
   begin
      Service.Registry := new Timer_Registry (Capacity);
      Service.Worker := new Timer_Worker (Service.Registry);
      return Service;
   exception
      when others =>
         if Service /= null then
            if Service.Registry /= null then
               Free_Registry (Service.Registry);
            end if;
            Free_Service (Service);
         end if;
         raise;
   end Create_Service;

   procedure Stop (Service : in out Timer_Service) is
      Attempts : Natural := 0;
   begin
      if Service.Registry = null then
         return;
      end if;

      Service.Registry.Request_Stop;

      while Service.Registry.Worker_Running and then Attempts < 10_000 loop
         delay 0.001;
         Attempts := Attempts + 1;
      end loop;
   end Stop;

   procedure Destroy (Service : in out Timer_Service_Access) is
   begin
      if Service = null then
         return;
      end if;

      Stop (Service.all);

      if Service.Worker /= null then
         Free_Worker (Service.Worker);
      end if;

      if Service.Registry /= null then
         Free_Registry (Service.Registry);
      end if;

      Free_Service (Service);
   end Destroy;

   function Schedule
     (Service : not null Timer_Service_Access;
      Delay_Ms : Aion.Types.Milliseconds;
      Name    : String := "timer") return Schedule_Results.Result_Type is
   begin
      return Schedule_At
        (Service  => Service,
         Deadline => Aion.Clock.Add (Aion.Clock.Now, Delay_Ms),
         Name     => Name);
   end Schedule;

   function Schedule_At
     (Service  : not null Timer_Service_Access;
      Deadline : Aion.Clock.Instant;
      Name     : String := "timer") return Schedule_Results.Result_Type is
      Id       : Timer_Id := No_Timer;
      Promise  : Timer_Promises.Promise_Handle := Timer_Promises.Null_Promise;
      Future   : Timer_Futures.Future_Handle := Timer_Futures.Null_Future;
      Item     : Timer_Record := Null_Record;
      Handle   : Timer_Handle := Null_Timer;
      Accepted : Boolean := False;
   begin
      if Service.Registry = null then
         return Schedule_Results.Failure
           (Aion.Errors.Invalid_State,
            "timer service is not initialized",
            "Aion.Timer_Queue.Schedule_At");
      end if;

      Id_Source.Next (Id);
      Timer_Promises.New_Promise (Promise, Future, Name);

      Item :=
        (Id       => Id,
         Name     => US.To_Unbounded_String (Name),
         Deadline => Deadline,
         Promise  => Promise,
         Future   => Future);

      Service.Registry.Insert (Item, Accepted);

      if not Accepted then
         declare
            Ignored : Timer_Promises.Operation_Results.Result_Type :=
              Timer_Promises.Fail
                (Promise,
                 Aion.Errors.Capacity_Exceeded,
                 "timer queue is full or stopping",
                 "Aion.Timer_Queue.Schedule_At");
            pragma Unreferenced (Ignored);
         begin
            null;
         end;

         return Schedule_Results.Failure
           (Aion.Errors.Capacity_Exceeded,
            "timer queue is full or stopping",
            "Aion.Timer_Queue.Schedule_At");
      end if;

      Handle :=
        (Id       => Id,
         Name     => US.To_Unbounded_String (Name),
         Deadline => Deadline,
         Future   => Future,
         Service  => Service);

      return Schedule_Results.Success (Handle);
   end Schedule_At;

   function Cancel (Timer : Timer_Handle) return Operation_Results.Result_Type is
      Item  : Timer_Record := Null_Record;
      Found : Boolean := False;
   begin
      if not Is_Valid (Timer) then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "timer handle is not valid",
            "Aion.Timer_Queue.Cancel");
      end if;

      Timer.Service.Registry.Cancel (Timer.Id, Item, Found);

      if not Found then
         if Timer_Futures.Is_Done (Timer.Future) then
            return Operation_Results.Success (True);
         end if;

         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "timer is not pending or has already fired",
            "Aion.Timer_Queue.Cancel");
      end if;

      Cancel_Record (Item, "timer cancelled by caller");
      return Operation_Results.Success (True);
   end Cancel;

   function Is_Valid (Timer : Timer_Handle) return Boolean is
   begin
      return Timer.Id /= No_Timer and then
        Timer.Service /= null and then
        Timer.Service.Registry /= null and then
        Timer_Futures.Is_Valid (Timer.Future);
   end Is_Valid;

   function Id_Of (Timer : Timer_Handle) return Timer_Id is
   begin
      return Timer.Id;
   end Id_Of;

   function Name_Of (Timer : Timer_Handle) return String is
   begin
      return US.To_String (Timer.Name);
   end Name_Of;

   function Deadline_Of (Timer : Timer_Handle) return Aion.Clock.Instant is
   begin
      return Timer.Deadline;
   end Deadline_Of;

   function Future_Of (Timer : Timer_Handle) return Timer_Futures.Future_Handle is
   begin
      return Timer.Future;
   end Future_Of;

   function Stats_Of (Service : Timer_Service) return Timer_Stats is
   begin
      if Service.Registry = null then
         return Timer_Stats'(others => <>);
      end if;

      return Service.Registry.Snapshot;
   end Stats_Of;

   function Pending_Count_Of (Service : Timer_Service) return Natural is
   begin
      if Service.Registry = null then
         return 0;
      end if;

      return Service.Registry.Depth;
   end Pending_Count_Of;

   function Is_Stopping (Service : Timer_Service) return Boolean is
   begin
      return Service.Registry = null or else Service.Registry.Stopping;
   end Is_Stopping;

   function Image (Timer : Timer_Handle) return String is
   begin
      if not Is_Valid (Timer) then
         return "timer[id=0,state=invalid]";
      end if;

      return
        "timer[id=" & Timer_Id_Image (Timer.Id) &
        ",name=" & Name_Of (Timer) &
        ",deadline=" & Aion.Clock.Image (Timer.Deadline) &
        ",future=" & Timer_Futures.Image (Timer.Future) &
        "]";
   end Image;

   function Image (Stats : Timer_Stats) return String is
   begin
      return
        "Timer_Stats(capacity=" & Natural_Image (Stats.Capacity) &
        ",pending=" & Natural_Image (Stats.Pending) &
        ",scheduled=" & Natural_Image (Stats.Scheduled_Total) &
        ",fired=" & Natural_Image (Stats.Fired_Total) &
        ",cancelled=" & Natural_Image (Stats.Cancelled_Total) &
        ",rejected=" & Natural_Image (Stats.Rejected_Total) &
        ",worker_running=" & Boolean_Image (Stats.Worker_Running) &
        ",stop_requested=" & Boolean_Image (Stats.Stop_Requested) &
        ")";
   end Image;

end Aion.Timer_Queue;
