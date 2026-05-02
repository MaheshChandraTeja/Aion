with Aion.Errors;
with Aion.Types;

package body Aion.Sync.Condvar is
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Task_Id;

   protected body Condvar_State is
      procedure Enqueue
        (Future   : in Wait_Futures.Future_Handle;
         Accepted : out Boolean) is
      begin
         if Count >= Max_Waiters then
            Failures := Failures + 1;
            Accepted := False;
         else
            Queue (Tail) := Future;
            if Tail = Max_Waiters then Tail := 1; else Tail := Tail + 1; end if;
            Count := Count + 1;
            Acquisitions := Acquisitions + 1;
            Accepted := True;
         end if;
      end Enqueue;

      procedure Pop_One
        (Future : out Wait_Futures.Future_Handle;
         Found  : out Boolean) is
      begin
         if Count = 0 then
            Future := Wait_Futures.Null_Future;
            Found := False;
         else
            Future := Queue (Head);
            Queue (Head) := Wait_Futures.Null_Future;
            if Head = Max_Waiters then Head := 1; else Head := Head + 1; end if;
            Count := Count - 1;
            Wakeups := Wakeups + 1;
            Releases := Releases + 1;
            Found := True;
         end if;
      end Pop_One;

      procedure Cancel
        (Future   : in Wait_Futures.Future_Handle;
         Accepted : out Boolean) is
         Cursor   : Positive := Head;
         Found_At : Natural := 0;
      begin
         Accepted := False;
         for Offset in 1 .. Count loop
            if Wait_Futures.Id_Of (Queue (Cursor)) = Wait_Futures.Id_Of (Future) then
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
         Queue (Tail) := Wait_Futures.Null_Future;
         Count := Count - 1;
         Cancellations := Cancellations + 1;
         Accepted := True;
      end Cancel;

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
   end Condvar_State;

   function Wait
     (Condvar : in out Async_Condvar;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "condvar.wait") return Wait_Futures.Future_Handle is
      pragma Unreferenced (Runtime);
      Future   : constant Wait_Futures.Future_Handle := Wait_Futures.Create (Name => Name);
      Accepted : Boolean;
      Ignored  : Wait_Futures.Operation_Results.Result_Type;
   begin
      Condvar.State.Enqueue (Future, Accepted);
      if not Accepted then
         Ignored := Wait_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "condition variable waiter queue is full", "Aion.Sync.Condvar.Wait");
      end if;
      return Future;
   end Wait;

   procedure Notify_One (Condvar : in out Async_Condvar) is
      Future  : Wait_Futures.Future_Handle;
      Found   : Boolean;
      Ignored : Wait_Futures.Operation_Results.Result_Type;
   begin
      Condvar.State.Pop_One (Future, Found);
      if Found then
         Ignored := Wait_Futures.Complete_Success (Future, True);
      end if;
   end Notify_One;

   procedure Notify_All (Condvar : in out Async_Condvar) is
      Future  : Wait_Futures.Future_Handle;
      Found   : Boolean;
      Ignored : Wait_Futures.Operation_Results.Result_Type;
   begin
      loop
         Condvar.State.Pop_One (Future, Found);
         exit when not Found;
         Ignored := Wait_Futures.Complete_Success (Future, True);
      end loop;
   end Notify_All;

   function Cancel_Waiter
     (Condvar : in out Async_Condvar;
      Future  : Wait_Futures.Future_Handle;
      Reason  : String := "condvar waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type is
      Accepted : Boolean;
      Ignored  : Wait_Futures.Operation_Results.Result_Type;
   begin
      Condvar.State.Cancel (Future, Accepted);
      if Accepted then
         Ignored := Wait_Futures.Complete_Cancelled (Future, Reason);
         return Aion.Sync.Boolean_Results.Success (True);
      end if;
      return Aion.Sync.Boolean_Results.Failure
        (Aion.Errors.Invalid_State,
         "future is not queued on this condition variable", "Aion.Sync.Condvar.Cancel_Waiter");
   end Cancel_Waiter;

   function Waiter_Count_Of (Condvar : Async_Condvar) return Natural is
   begin
      return Condvar.State.Waiters;
   end Waiter_Count_Of;

   function Stats_Of (Condvar : Async_Condvar) return Aion.Sync.Primitive_Stats is
   begin
      return Condvar.State.Snapshot;
   end Stats_Of;

end Aion.Sync.Condvar;
