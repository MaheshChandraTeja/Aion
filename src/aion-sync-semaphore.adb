with Aion.Errors;
with Aion.Types;

package body Aion.Sync.Semaphore is
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Task_Id;

   function Make_Permit (Token : Permit_Token) return Permit_Guard is
   begin
      return (Token => Token, Valid => Token /= 0);
   end Make_Permit;

   protected body Semaphore_State is
      procedure Bump_Token is
      begin
         Next_Token := Next_Token + 1;
         if Next_Token = 0 then
            Next_Token := 1;
         end if;
      end Bump_Token;

      procedure Push
        (Future  : in Permit_Futures.Future_Handle;
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

      procedure Pop
        (Future : out Permit_Futures.Future_Handle;
         Found  : out Boolean) is
      begin
         if Count = 0 then
            Future := Permit_Futures.Null_Future;
            Found := False;
         else
            Future := Queue (Head);
            Queue (Head) := Permit_Futures.Null_Future;
            if Head = Max_Waiters then
               Head := 1;
            else
               Head := Head + 1;
            end if;
            Count := Count - 1;
            Found := True;
         end if;
      end Pop;

      procedure Request
        (Future    : in Permit_Futures.Future_Handle;
         Immediate : out Boolean;
         Permit    : out Permit_Guard;
         Accepted  : out Boolean) is
      begin
         if Free > 0 then
            Free := Free - 1;
            Permit := Make_Permit (Next_Token);
            Bump_Token;
            Acquisitions := Acquisitions + 1;
            Immediate := True;
            Accepted := True;
         else
            Push (Future, Accepted);
            Permit := (Token => 0, Valid => False);
            Immediate := False;
         end if;
      end Request;

      procedure Try_Request
        (Accepted : out Boolean;
         Permit   : out Permit_Guard) is
      begin
         if Free = 0 then
            Accepted := False;
            Permit := (Token => 0, Valid => False);
         else
            Free := Free - 1;
            Permit := Make_Permit (Next_Token);
            Bump_Token;
            Acquisitions := Acquisitions + 1;
            Accepted := True;
         end if;
      end Try_Request;

      procedure Release_One
        (Accepted : out Boolean;
         Next     : out Permit_Futures.Future_Handle;
         Permit   : out Permit_Guard;
         Has_Next : out Boolean) is
      begin
         Next := Permit_Futures.Null_Future;
         Permit := (Token => 0, Valid => False);
         Has_Next := False;
         Accepted := True;
         Releases := Releases + 1;

         Pop (Next, Has_Next);
         if Has_Next then
            Permit := Make_Permit (Next_Token);
            Bump_Token;
            Acquisitions := Acquisitions + 1;
            Wakeups := Wakeups + 1;
         elsif Free < Maximum_Permits then
            Free := Free + 1;
         else
            Failures := Failures + 1;
            Accepted := False;
         end if;
      end Release_One;

      procedure Cancel
        (Future   : in Permit_Futures.Future_Handle;
         Accepted : out Boolean) is
         Cursor   : Positive := Head;
         Found_At : Natural := 0;
      begin
         Accepted := False;
         for Offset in 1 .. Count loop
            if Permit_Futures.Id_Of (Queue (Cursor)) = Permit_Futures.Id_Of (Future) then
               Found_At := Offset;
               exit;
            end if;
            if Cursor = Max_Waiters then
               Cursor := 1;
            else
               Cursor := Cursor + 1;
            end if;
         end loop;

         if Found_At = 0 then
            Failures := Failures + 1;
            return;
         end if;

         for Shift in Found_At .. Count - 1 loop
            declare
               To_Index   : Positive := Head;
               From_Index : Positive;
            begin
               for I in 1 .. Shift - 1 loop
                  if To_Index = Max_Waiters then
                     To_Index := 1;
                  else
                     To_Index := To_Index + 1;
                  end if;
               end loop;
               From_Index := To_Index;
               if From_Index = Max_Waiters then
                  From_Index := 1;
               else
                  From_Index := From_Index + 1;
               end if;
               Queue (To_Index) := Queue (From_Index);
            end;
         end loop;

         if Tail = 1 then
            Tail := Max_Waiters;
         else
            Tail := Tail - 1;
         end if;
         Queue (Tail) := Permit_Futures.Null_Future;
         Count := Count - 1;
         Cancellations := Cancellations + 1;
         Accepted := True;
      end Cancel;

      function Available return Natural is
      begin
         return Free;
      end Available;

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
   end Semaphore_State;

   function Acquire
     (Semaphore : in out Async_Semaphore;
      Runtime   : access Aion.Runtime.Runtime_Handle := null;
      Name      : String := "semaphore.acquire") return Permit_Futures.Future_Handle is
      pragma Unreferenced (Runtime);
      Future    : constant Permit_Futures.Future_Handle := Permit_Futures.Create (Name => Name);
      Permit    : Permit_Guard;
      Immediate : Boolean;
      Accepted  : Boolean;
      Ignored   : Permit_Futures.Operation_Results.Result_Type;
   begin
      Semaphore.State.Request (Future, Immediate, Permit, Accepted);
      if not Accepted then
         Ignored := Permit_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "semaphore waiter queue is full", "Aion.Sync.Semaphore.Acquire");
      elsif Immediate then
         Ignored := Permit_Futures.Complete_Success (Future, Permit);
      end if;
      return Future;
   end Acquire;

   function Try_Acquire
     (Semaphore : in out Async_Semaphore) return Permit_Results.Result_Type is
      Accepted : Boolean;
      Permit   : Permit_Guard;
   begin
      Semaphore.State.Try_Request (Accepted, Permit);
      if Accepted then
         return Permit_Results.Success (Permit);
      end if;
      return Permit_Results.Failure
        (Aion.Errors.Invalid_State,
         "semaphore has no available permits", "Aion.Sync.Semaphore.Try_Acquire");
   end Try_Acquire;

   function Release
     (Semaphore : in out Async_Semaphore;
      Permit    : in out Permit_Guard) return Aion.Sync.Boolean_Results.Result_Type is
      Accepted : Boolean;
      Next     : Permit_Futures.Future_Handle;
      Next_Permit : Permit_Guard;
      Has_Next : Boolean;
      Ignored  : Permit_Futures.Operation_Results.Result_Type;
   begin
      if not Permit.Valid then
         return Aion.Sync.Boolean_Results.Failure
           (Aion.Errors.Invalid_State,
            "invalid semaphore permit", "Aion.Sync.Semaphore.Release");
      end if;

      Semaphore.State.Release_One (Accepted, Next, Next_Permit, Has_Next);
      if not Accepted then
         return Aion.Sync.Boolean_Results.Failure
           (Aion.Errors.Invalid_State,
            "semaphore permit release would exceed maximum permits",
            "Aion.Sync.Semaphore.Release");
      end if;

      Permit := (Token => 0, Valid => False);
      if Has_Next then
         Ignored := Permit_Futures.Complete_Success (Next, Next_Permit);
      end if;
      return Aion.Sync.Boolean_Results.Success (True);
   end Release;

   function Cancel_Waiter
     (Semaphore : in out Async_Semaphore;
      Future    : Permit_Futures.Future_Handle;
      Reason    : String := "semaphore waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type is
      Accepted : Boolean;
      Ignored  : Permit_Futures.Operation_Results.Result_Type;
   begin
      Semaphore.State.Cancel (Future, Accepted);
      if Accepted then
         Ignored := Permit_Futures.Complete_Cancelled (Future, Reason);
         return Aion.Sync.Boolean_Results.Success (True);
      end if;
      return Aion.Sync.Boolean_Results.Failure
        (Aion.Errors.Invalid_State,
         "future is not queued on this semaphore", "Aion.Sync.Semaphore.Cancel_Waiter");
   end Cancel_Waiter;

   function Available_Of (Semaphore : Async_Semaphore) return Natural is
   begin
      return Semaphore.State.Available;
   end Available_Of;

   function Waiter_Count_Of (Semaphore : Async_Semaphore) return Natural is
   begin
      return Semaphore.State.Waiters;
   end Waiter_Count_Of;

   function Stats_Of (Semaphore : Async_Semaphore) return Aion.Sync.Primitive_Stats is
   begin
      return Semaphore.State.Snapshot;
   end Stats_Of;

end Aion.Sync.Semaphore;
