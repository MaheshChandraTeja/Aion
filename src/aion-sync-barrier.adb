with Aion.Errors;
with Aion.Types;

package body Aion.Sync.Barrier is
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Task_Id;

   protected body Barrier_State is
      procedure Arrive
        (Future     : in Barrier_Futures.Future_Handle;
         Accepted   : out Boolean;
         Released   : out Boolean;
         Generation : out Natural) is
      begin
         Accepted := False;
         Released := False;
         Generation := Barrier_State.Generation;

         if Count >= Max_Waiters then
            Failures := Failures + 1;
            return;
         end if;

         Queue (Tail) := Future;
         if Tail = Max_Waiters then Tail := 1; else Tail := Tail + 1; end if;
         Count := Count + 1;
         Acquisitions := Acquisitions + 1;
         Accepted := True;

         if Count >= Parties then
            Barrier_State.Generation := Barrier_State.Generation + 1;
            Generation := Barrier_State.Generation;
            Release_Count := Parties;
            Release_Index := 0;
            Released := True;
            Releases := Releases + 1;
         end if;
      end Arrive;

      procedure Pop_Released
        (Future    : out Barrier_Futures.Future_Handle;
         Outcome   : out Barrier_Outcome;
         Found     : out Boolean) is
      begin
         if Release_Count = 0 or else Count = 0 then
            Future := Barrier_Futures.Null_Future;
            Outcome := (Generation => Generation, Is_Leader => False);
            Found := False;
            return;
         end if;

         Future := Queue (Head);
         Queue (Head) := Barrier_Futures.Null_Future;
         if Head = Max_Waiters then Head := 1; else Head := Head + 1; end if;
         Count := Count - 1;
         Release_Index := Release_Index + 1;
         Release_Count := Release_Count - 1;
         Wakeups := Wakeups + 1;

         Outcome := (Generation => Generation, Is_Leader => Release_Index = 1);
         Found := True;
      end Pop_Released;

      procedure Cancel
        (Future   : in Barrier_Futures.Future_Handle;
         Accepted : out Boolean) is
         Cursor   : Positive := Head;
         Found_At : Natural := 0;
      begin
         Accepted := False;

         if Release_Count /= 0 then
            Failures := Failures + 1;
            return;
         end if;

         for Offset in 1 .. Count loop
            if Barrier_Futures.Id_Of (Queue (Cursor)) = Barrier_Futures.Id_Of (Future) then
               Found_At := Offset; exit;
            end if;
            if Cursor = Max_Waiters then Cursor := 1; else Cursor := Cursor + 1; end if;
         end loop;

         if Found_At = 0 then
            Failures := Failures + 1; return;
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
         Queue (Tail) := Barrier_Futures.Null_Future;
         Count := Count - 1;
         Cancellations := Cancellations + 1;
         Accepted := True;
      end Cancel;

      function Waiting return Natural is
      begin
         return Count;
      end Waiting;

      function Current_Generation return Natural is
      begin
         return Generation;
      end Current_Generation;

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
   end Barrier_State;

   function Arrive_And_Wait
     (Barrier : in out Async_Barrier;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "barrier.wait") return Barrier_Futures.Future_Handle is
      pragma Unreferenced (Runtime);
      Future    : constant Barrier_Futures.Future_Handle := Barrier_Futures.Create (Name => Name);
      Accepted  : Boolean;
      Released  : Boolean;
      Gen       : Natural;
      Next      : Barrier_Futures.Future_Handle;
      Outcome   : Barrier_Outcome;
      Found     : Boolean;
      Ignored   : Barrier_Futures.Operation_Results.Result_Type;
   begin
      Barrier.State.Arrive (Future, Accepted, Released, Gen);
      if not Accepted then
         Ignored := Barrier_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "barrier waiter queue is full or currently releasing",
            "Aion.Sync.Barrier.Arrive_And_Wait");
      end if;

      if Released then
         loop
            Barrier.State.Pop_Released (Next, Outcome, Found);
            exit when not Found;
            Ignored := Barrier_Futures.Complete_Success (Next, Outcome);
         end loop;
      end if;

      return Future;
   end Arrive_And_Wait;

   function Cancel_Waiter
     (Barrier : in out Async_Barrier;
      Future  : Barrier_Futures.Future_Handle;
      Reason  : String := "barrier waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type is
      Accepted : Boolean;
      Ignored  : Barrier_Futures.Operation_Results.Result_Type;
   begin
      Barrier.State.Cancel (Future, Accepted);
      if Accepted then
         Ignored := Barrier_Futures.Complete_Cancelled (Future, Reason);
         return Aion.Sync.Boolean_Results.Success (True);
      end if;
      return Aion.Sync.Boolean_Results.Failure
        (Aion.Errors.Invalid_State,
         "future is not queued on this barrier", "Aion.Sync.Barrier.Cancel_Waiter");
   end Cancel_Waiter;

   function Waiting_Of (Barrier : Async_Barrier) return Natural is
   begin
      return Barrier.State.Waiting;
   end Waiting_Of;

   function Generation_Of (Barrier : Async_Barrier) return Natural is
   begin
      return Barrier.State.Current_Generation;
   end Generation_Of;

   function Stats_Of (Barrier : Async_Barrier) return Aion.Sync.Primitive_Stats is
   begin
      return Barrier.State.Snapshot;
   end Stats_Of;

end Aion.Sync.Barrier;
