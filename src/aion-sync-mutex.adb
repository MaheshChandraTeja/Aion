with Aion.Errors;
with Aion.Types;

package body Aion.Sync.Mutex is
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Task_Id;

   function Make_Guard (Token : Lock_Token) return Lock_Guard is
   begin
      return (Token => Token, Valid => Token /= 0);
   end Make_Guard;

   protected body Mutex_State is
      procedure Bump_Token is
      begin
         Next_Token := Next_Token + 1;
         if Next_Token = 0 then
            Next_Token := 1;
         end if;
      end Bump_Token;

      procedure Push
        (Future  : in Lock_Futures.Future_Handle;
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
        (Future : out Lock_Futures.Future_Handle;
         Found  : out Boolean) is
      begin
         if Count = 0 then
            Future := Lock_Futures.Null_Future;
            Found := False;
         else
            Future := Queue (Head);
            Queue (Head) := Lock_Futures.Null_Future;
            if Head = Max_Waiters then
               Head := 1;
            else
               Head := Head + 1;
            end if;
            Count := Count - 1;
            Found := True;
         end if;
      end Pop;

      procedure Request_Lock
        (Future   : in Lock_Futures.Future_Handle;
         Immediate : out Boolean;
         Guard     : out Lock_Guard;
         Accepted  : out Boolean) is
      begin
         if not Is_Held then
            Is_Held := True;
            Owner := Next_Token;
            Guard := Make_Guard (Owner);
            Bump_Token;
            Acquisitions := Acquisitions + 1;
            Immediate := True;
            Accepted := True;
         else
            Push (Future, Accepted);
            Guard := (Token => 0, Valid => False);
            Immediate := False;
         end if;
      end Request_Lock;

      procedure Try_Request
        (Accepted : out Boolean;
         Guard    : out Lock_Guard) is
      begin
         if Is_Held then
            Accepted := False;
            Guard := (Token => 0, Valid => False);
         else
            Is_Held := True;
            Owner := Next_Token;
            Guard := Make_Guard (Owner);
            Bump_Token;
            Acquisitions := Acquisitions + 1;
            Accepted := True;
         end if;
      end Try_Request;

      procedure Release
        (Token      : in Lock_Token;
         Accepted   : out Boolean;
         Next       : out Lock_Futures.Future_Handle;
         Next_Guard : out Lock_Guard;
         Has_Next   : out Boolean) is
      begin
         Next := Lock_Futures.Null_Future;
         Next_Guard := (Token => 0, Valid => False);
         Has_Next := False;

         if (not Is_Held) or else Token = 0 or else Token /= Owner then
            Failures := Failures + 1;
            Accepted := False;
            return;
         end if;

         Releases := Releases + 1;
         Accepted := True;

         Pop (Next, Has_Next);
         if Has_Next then
            Owner := Next_Token;
            Next_Guard := Make_Guard (Owner);
            Bump_Token;
            Acquisitions := Acquisitions + 1;
            Wakeups := Wakeups + 1;
            Is_Held := True;
         else
            Owner := 0;
            Is_Held := False;
         end if;
      end Release;

      procedure Cancel
        (Future   : in Lock_Futures.Future_Handle;
         Accepted : out Boolean) is
         Cursor   : Positive := Head;
         Found_At : Natural := 0;
      begin
         Accepted := False;

         for Offset in 1 .. Count loop
            if Lock_Futures.Id_Of (Queue (Cursor)) = Lock_Futures.Id_Of (Future) then
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
         Queue (Tail) := Lock_Futures.Null_Future;
         Count := Count - 1;
         Cancellations := Cancellations + 1;
         Accepted := True;
      end Cancel;

      function Locked return Boolean is
      begin
         return Is_Held;
      end Locked;

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
   end Mutex_State;

   function Lock
     (Mutex   : in out Async_Mutex;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "mutex.lock") return Lock_Futures.Future_Handle is
      pragma Unreferenced (Runtime);
      Future    : constant Lock_Futures.Future_Handle := Lock_Futures.Create (Name => Name);
      Guard     : Lock_Guard;
      Immediate : Boolean;
      Accepted  : Boolean;
      Ignored   : Lock_Futures.Operation_Results.Result_Type;
   begin
      Mutex.State.Request_Lock (Future, Immediate, Guard, Accepted);
      if not Accepted then
         Ignored := Lock_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "mutex waiter queue is full", "Aion.Sync.Mutex.Lock");
      elsif Immediate then
         Ignored := Lock_Futures.Complete_Success (Future, Guard);
      end if;
      return Future;
   end Lock;

   function Try_Lock
     (Mutex : in out Async_Mutex) return Guard_Results.Result_Type is
      Accepted : Boolean;
      Guard    : Lock_Guard;
   begin
      Mutex.State.Try_Request (Accepted, Guard);
      if Accepted then
         return Guard_Results.Success (Guard);
      end if;
      return Guard_Results.Failure
        (Aion.Errors.Invalid_State,
         "mutex is already locked", "Aion.Sync.Mutex.Try_Lock");
   end Try_Lock;

   function Unlock
     (Mutex : in out Async_Mutex;
      Guard : in out Lock_Guard) return Aion.Sync.Boolean_Results.Result_Type is
      Accepted   : Boolean;
      Next       : Lock_Futures.Future_Handle;
      Next_Guard : Lock_Guard;
      Has_Next   : Boolean;
      Ignored    : Lock_Futures.Operation_Results.Result_Type;
   begin
      Mutex.State.Release (Guard.Token, Accepted, Next, Next_Guard, Has_Next);
      if not Accepted then
         return Aion.Sync.Boolean_Results.Failure
           (Aion.Errors.Invalid_State,
            "mutex unlock attempted with invalid guard", "Aion.Sync.Mutex.Unlock");
      end if;

      Guard := (Token => 0, Valid => False);

      if Has_Next then
         Ignored := Lock_Futures.Complete_Success (Next, Next_Guard);
      end if;
      return Aion.Sync.Boolean_Results.Success (True);
   end Unlock;

   function Cancel_Waiter
     (Mutex  : in out Async_Mutex;
      Future : Lock_Futures.Future_Handle;
      Reason : String := "mutex waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type is
      Accepted : Boolean;
      Ignored  : Lock_Futures.Operation_Results.Result_Type;
   begin
      Mutex.State.Cancel (Future, Accepted);
      if Accepted then
         Ignored := Lock_Futures.Complete_Cancelled (Future, Reason);
         return Aion.Sync.Boolean_Results.Success (True);
      end if;
      return Aion.Sync.Boolean_Results.Failure
        (Aion.Errors.Invalid_State,
         "future is not queued on this mutex", "Aion.Sync.Mutex.Cancel_Waiter");
   end Cancel_Waiter;

   function Is_Locked (Mutex : Async_Mutex) return Boolean is
   begin
      return Mutex.State.Locked;
   end Is_Locked;

   function Waiter_Count_Of (Mutex : Async_Mutex) return Natural is
   begin
      return Mutex.State.Waiters;
   end Waiter_Count_Of;

   function Stats_Of (Mutex : Async_Mutex) return Aion.Sync.Primitive_Stats is
   begin
      return Mutex.State.Snapshot;
   end Stats_Of;

end Aion.Sync.Mutex;
