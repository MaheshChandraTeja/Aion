with Aion.Errors;
with Aion.Types;

package body Aion.Sync.Event is
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Task_Id;

   protected body Event_State is
      procedure Push
        (Future  : in Event_Futures.Future_Handle;
         Accepted : out Boolean) is
      begin
         if Count >= Max_Waiters then
            Failures := Failures + 1;
            Accepted := False;
         else
            Queue (Tail) := Future;
            if Tail = Max_Waiters then
               Tail := 1;
            else
               Tail := Tail + 1;
            end if;
            Count := Count + 1;
            Accepted := True;
         end if;
      end Push;

      procedure Request_Wait
        (Future   : in Event_Futures.Future_Handle;
         Immediate : out Boolean;
         Accepted  : out Boolean) is
      begin
         if Flag then
            Immediate := True;
            Accepted := True;
            Acquisitions := Acquisitions + 1;
            if Mode = Auto_Reset then
               Flag := False;
            end if;
         else
            Push (Future, Accepted);
            Immediate := False;
         end if;
      end Request_Wait;

      procedure Signal is
      begin
         Flag := True;
         Releases := Releases + 1;
      end Signal;

      procedure Clear is
      begin
         Flag := False;
      end Clear;

      procedure Pop_Ready
        (Future : out Event_Futures.Future_Handle;
         Found  : out Boolean) is
      begin
         if Count = 0 or else not Flag then
            Future := Event_Futures.Null_Future;
            Found := False;
            return;
         end if;

         Future := Queue (Head);
         Queue (Head) := Event_Futures.Null_Future;
         if Head = Max_Waiters then
            Head := 1;
         else
            Head := Head + 1;
         end if;
         Count := Count - 1;
         Wakeups := Wakeups + 1;
         Found := True;

         if Mode = Auto_Reset then
            Flag := False;
         end if;
      end Pop_Ready;

      procedure Cancel
        (Future   : in Event_Futures.Future_Handle;
         Accepted : out Boolean) is
         Cursor   : Positive := Head;
         Found_At : Natural := 0;
      begin
         Accepted := False;
         for Offset in 1 .. Count loop
            if Event_Futures.Id_Of (Queue (Cursor)) = Event_Futures.Id_Of (Future) then
               Found_At := Offset;
               exit;
            end if;
            if Cursor = Max_Waiters then Cursor := 1; else Cursor := Cursor + 1; end if;
         end loop;

         if Found_At = 0 then
            Failures := Failures + 1;
            return;
         end if;

         for Shift in Found_At .. Count - 1 loop
            declare
               To_Index : Positive := Head;
               From_Index : Positive;
            begin
               for I in 1 .. Shift - 1 loop
                  if To_Index = Max_Waiters then To_Index := 1; else To_Index := To_Index + 1; end if;
               end loop;
               From_Index := To_Index;
               if From_Index = Max_Waiters then From_Index := 1; else From_Index := From_Index + 1; end if;
               Queue (To_Index) := Queue (From_Index);
            end;
         end loop;
         if Tail = 1 then Tail := Max_Waiters; else Tail := Tail - 1; end if;
         Queue (Tail) := Event_Futures.Null_Future;
         Count := Count - 1;
         Cancellations := Cancellations + 1;
         Accepted := True;
      end Cancel;

      function Signaled return Boolean is
      begin
         return Flag;
      end Signaled;

      function Waiters return Natural is
      begin
         return Count;
      end Waiters;

      function Snapshot return Aion.Sync.Primitive_Stats is
      begin
         return
           (Waiters       => Count,
            Wakeups       => Wakeups,
            Acquisitions  => Acquisitions,
            Releases      => Releases,
            Cancellations => Cancellations,
            Failures      => Failures);
      end Snapshot;
   end Event_State;

   function Wait
     (Event   : in out Async_Event;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "event.wait") return Event_Futures.Future_Handle is
      pragma Unreferenced (Runtime);
      Future    : constant Event_Futures.Future_Handle := Event_Futures.Create (Name => Name);
      Immediate : Boolean;
      Accepted  : Boolean;
      Ignored   : Event_Futures.Operation_Results.Result_Type;
   begin
      Event.State.Request_Wait (Future, Immediate, Accepted);
      if not Accepted then
         Ignored := Event_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "event waiter queue is full", "Aion.Sync.Event.Wait");
      elsif Immediate then
         Ignored := Event_Futures.Complete_Success (Future, True);
      end if;
      return Future;
   end Wait;

   procedure Set (Event : in out Async_Event) is
      Future  : Event_Futures.Future_Handle;
      Found   : Boolean;
      Ignored : Event_Futures.Operation_Results.Result_Type;
   begin
      Event.State.Signal;
      loop
         Event.State.Pop_Ready (Future, Found);
         exit when not Found;
         Ignored := Event_Futures.Complete_Success (Future, True);
      end loop;
   end Set;

   procedure Reset (Event : in out Async_Event) is
   begin
      Event.State.Clear;
   end Reset;

   function Cancel_Waiter
     (Event  : in out Async_Event;
      Future : Event_Futures.Future_Handle;
      Reason : String := "event waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type is
      Accepted : Boolean;
      Ignored  : Event_Futures.Operation_Results.Result_Type;
   begin
      Event.State.Cancel (Future, Accepted);
      if Accepted then
         Ignored := Event_Futures.Complete_Cancelled (Future, Reason);
         return Aion.Sync.Boolean_Results.Success (True);
      end if;
      return Aion.Sync.Boolean_Results.Failure
        (Aion.Errors.Invalid_State,
         "future is not queued on this event", "Aion.Sync.Event.Cancel_Waiter");
   end Cancel_Waiter;

   function Is_Set (Event : Async_Event) return Boolean is
   begin
      return Event.State.Signaled;
   end Is_Set;

   function Waiter_Count_Of (Event : Async_Event) return Natural is
   begin
      return Event.State.Waiters;
   end Waiter_Count_Of;

   function Stats_Of (Event : Async_Event) return Aion.Sync.Primitive_Stats is
   begin
      return Event.State.Snapshot;
   end Stats_Of;

end Aion.Sync.Event;
