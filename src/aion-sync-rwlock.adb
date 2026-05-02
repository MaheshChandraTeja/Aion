with Aion.Errors;
with Aion.Types;

package body Aion.Sync.RWLock is
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Task_Id;

   function Make_Guard (Token : Guard_Token; Kind : Guard_Kind) return RW_Guard is
   begin
      return (Token => Token, Kind => Kind, Valid => Token /= 0);
   end Make_Guard;

   protected body RWLock_State is
      procedure Bump_Token is
      begin
         Next_Token := Next_Token + 1;
         if Next_Token = 0 then
            Next_Token := 1;
         end if;
      end Bump_Token;

      procedure Push
        (Kind     : in Wait_Kind;
         Future   : in Guard_Futures.Future_Handle;
         Accepted : out Boolean) is
      begin
         if Count >= Max_Waiters then
            Failures := Failures + 1;
            Accepted := False;
         else
            Queue (Tail) := (Kind => Kind, Future => Future);
            if Tail = Max_Waiters then Tail := 1; else Tail := Tail + 1; end if;
            Count := Count + 1;
            Accepted := True;
         end if;
      end Push;

      procedure Request
        (Kind      : in Wait_Kind;
         Future    : in Guard_Futures.Future_Handle;
         Immediate : out Boolean;
         Guard     : out RW_Guard;
         Accepted  : out Boolean) is
      begin
         if Kind = Waiting_Read then
            if (not Writer_Active) and then Count = 0 then
               Active_Readers := Active_Readers + 1;
               Guard := Make_Guard (Next_Token, Read_Guard);
               Bump_Token;
               Immediate := True;
               Accepted := True;
               Acquisitions := Acquisitions + 1;
            else
               Push (Kind, Future, Accepted);
               Guard := (Token => 0, Kind => Read_Guard, Valid => False);
               Immediate := False;
            end if;
         else
            if (not Writer_Active) and then Active_Readers = 0 then
               Writer_Active := True;
               Guard := Make_Guard (Next_Token, Write_Guard);
               Bump_Token;
               Immediate := True;
               Accepted := True;
               Acquisitions := Acquisitions + 1;
            else
               Push (Kind, Future, Accepted);
               Guard := (Token => 0, Kind => Write_Guard, Valid => False);
               Immediate := False;
            end if;
         end if;
      end Request;

      procedure Try_Request
        (Kind     : in Wait_Kind;
         Accepted : out Boolean;
         Guard    : out RW_Guard) is
      begin
         if Kind = Waiting_Read then
            if (not Writer_Active) and then Count = 0 then
               Active_Readers := Active_Readers + 1;
               Guard := Make_Guard (Next_Token, Read_Guard);
               Bump_Token;
               Acquisitions := Acquisitions + 1;
               Accepted := True;
            else
               Guard := (Token => 0, Kind => Read_Guard, Valid => False);
               Accepted := False;
            end if;
         else
            if (not Writer_Active) and then Active_Readers = 0 then
               Writer_Active := True;
               Guard := Make_Guard (Next_Token, Write_Guard);
               Bump_Token;
               Acquisitions := Acquisitions + 1;
               Accepted := True;
            else
               Guard := (Token => 0, Kind => Write_Guard, Valid => False);
               Accepted := False;
            end if;
         end if;
      end Try_Request;

      procedure Release
        (Guard    : in RW_Guard;
         Accepted : out Boolean) is
      begin
         Accepted := False;
         if not Guard.Valid then
            Failures := Failures + 1;
            return;
         end if;

         if Guard.Kind = Read_Guard then
            if Active_Readers = 0 then
               Failures := Failures + 1;
               return;
            end if;
            Active_Readers := Active_Readers - 1;
         else
            if not Writer_Active then
               Failures := Failures + 1;
               return;
            end if;
            Writer_Active := False;
         end if;

         Releases := Releases + 1;
         Accepted := True;
      end Release;

      procedure Pop_Ready
        (Future : out Guard_Futures.Future_Handle;
         Guard  : out RW_Guard;
         Found  : out Boolean) is
         Item : Wait_Item;
      begin
         Future := Guard_Futures.Null_Future;
         Guard := (Token => 0, Kind => Read_Guard, Valid => False);
         Found := False;

         if Count = 0 or else Writer_Active or else Active_Readers /= 0 then
            return;
         end if;

         Item := Queue (Head);

         if Item.Kind = Waiting_Write then
            Queue (Head) := (Kind => Waiting_Read, Future => Guard_Futures.Null_Future);
            if Head = Max_Waiters then Head := 1; else Head := Head + 1; end if;
            Count := Count - 1;
            Writer_Active := True;
            Future := Item.Future;
            Guard := Make_Guard (Next_Token, Write_Guard);
            Bump_Token;
            Found := True;
         else
            Queue (Head) := (Kind => Waiting_Read, Future => Guard_Futures.Null_Future);
            if Head = Max_Waiters then Head := 1; else Head := Head + 1; end if;
            Count := Count - 1;
            Active_Readers := Active_Readers + 1;
            Future := Item.Future;
            Guard := Make_Guard (Next_Token, Read_Guard);
            Bump_Token;
            Found := True;
         end if;

         if Found then
            Wakeups := Wakeups + 1;
            Acquisitions := Acquisitions + 1;
         end if;
      end Pop_Ready;

      procedure Cancel
        (Future   : in Guard_Futures.Future_Handle;
         Accepted : out Boolean) is
         Cursor   : Positive := Head;
         Found_At : Natural := 0;
      begin
         Accepted := False;
         for Offset in 1 .. Count loop
            if Guard_Futures.Id_Of (Queue (Cursor).Future) = Guard_Futures.Id_Of (Future) then
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
         Queue (Tail) := (Kind => Waiting_Read, Future => Guard_Futures.Null_Future);
         Count := Count - 1;
         Cancellations := Cancellations + 1;
         Accepted := True;
      end Cancel;

      function Readers return Natural is
      begin
         return Active_Readers;
      end Readers;

      function Writer return Boolean is
      begin
         return Writer_Active;
      end Writer;

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
   end RWLock_State;

   procedure Drain_Ready (Lock : in out Async_RWLock) is
      Future  : Guard_Futures.Future_Handle;
      Guard   : RW_Guard;
      Found   : Boolean;
      Ignored : Guard_Futures.Operation_Results.Result_Type;
   begin
      loop
         Lock.State.Pop_Ready (Future, Guard, Found);
         exit when not Found;
         Ignored := Guard_Futures.Complete_Success (Future, Guard);
      end loop;
   end Drain_Ready;

   function Read_Lock
     (Lock    : in out Async_RWLock;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "rwlock.read") return Guard_Futures.Future_Handle is
      pragma Unreferenced (Runtime);
      Future : constant Guard_Futures.Future_Handle := Guard_Futures.Create (Name => Name);
      Immediate : Boolean;
      Accepted  : Boolean;
      Guard     : RW_Guard;
      Ignored   : Guard_Futures.Operation_Results.Result_Type;
   begin
      Lock.State.Request (Waiting_Read, Future, Immediate, Guard, Accepted);
      if not Accepted then
         Ignored := Guard_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "rwlock waiter queue is full", "Aion.Sync.RWLock.Read_Lock");
      elsif Immediate then
         Ignored := Guard_Futures.Complete_Success (Future, Guard);
      end if;
      return Future;
   end Read_Lock;

   function Write_Lock
     (Lock    : in out Async_RWLock;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "rwlock.write") return Guard_Futures.Future_Handle is
      pragma Unreferenced (Runtime);
      Future : constant Guard_Futures.Future_Handle := Guard_Futures.Create (Name => Name);
      Immediate : Boolean;
      Accepted  : Boolean;
      Guard     : RW_Guard;
      Ignored   : Guard_Futures.Operation_Results.Result_Type;
   begin
      Lock.State.Request (Waiting_Write, Future, Immediate, Guard, Accepted);
      if not Accepted then
         Ignored := Guard_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "rwlock waiter queue is full", "Aion.Sync.RWLock.Write_Lock");
      elsif Immediate then
         Ignored := Guard_Futures.Complete_Success (Future, Guard);
      end if;
      return Future;
   end Write_Lock;

   function Try_Read_Lock
     (Lock : in out Async_RWLock) return Guard_Results.Result_Type is
      Accepted : Boolean;
      Guard    : RW_Guard;
   begin
      Lock.State.Try_Request (Waiting_Read, Accepted, Guard);
      if Accepted then
         return Guard_Results.Success (Guard);
      end if;
      return Guard_Results.Failure
        (Aion.Errors.Invalid_State,
         "rwlock read lock is unavailable", "Aion.Sync.RWLock.Try_Read_Lock");
   end Try_Read_Lock;

   function Try_Write_Lock
     (Lock : in out Async_RWLock) return Guard_Results.Result_Type is
      Accepted : Boolean;
      Guard    : RW_Guard;
   begin
      Lock.State.Try_Request (Waiting_Write, Accepted, Guard);
      if Accepted then
         return Guard_Results.Success (Guard);
      end if;
      return Guard_Results.Failure
        (Aion.Errors.Invalid_State,
         "rwlock write lock is unavailable", "Aion.Sync.RWLock.Try_Write_Lock");
   end Try_Write_Lock;

   function Unlock
     (Lock  : in out Async_RWLock;
      Guard : in out RW_Guard) return Aion.Sync.Boolean_Results.Result_Type is
      Accepted : Boolean;
   begin
      Lock.State.Release (Guard, Accepted);
      if not Accepted then
         return Aion.Sync.Boolean_Results.Failure
           (Aion.Errors.Invalid_State,
            "invalid rwlock guard", "Aion.Sync.RWLock.Unlock");
      end if;

      Guard := (Token => 0, Kind => Read_Guard, Valid => False);
      Drain_Ready (Lock);
      return Aion.Sync.Boolean_Results.Success (True);
   end Unlock;

   function Cancel_Waiter
     (Lock   : in out Async_RWLock;
      Future : Guard_Futures.Future_Handle;
      Reason : String := "rwlock waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type is
      Accepted : Boolean;
      Ignored  : Guard_Futures.Operation_Results.Result_Type;
   begin
      Lock.State.Cancel (Future, Accepted);
      if Accepted then
         Ignored := Guard_Futures.Complete_Cancelled (Future, Reason);
         return Aion.Sync.Boolean_Results.Success (True);
      end if;
      return Aion.Sync.Boolean_Results.Failure
        (Aion.Errors.Invalid_State,
         "future is not queued on this rwlock", "Aion.Sync.RWLock.Cancel_Waiter");
   end Cancel_Waiter;

   function Reader_Count_Of (Lock : Async_RWLock) return Natural is
   begin
      return Lock.State.Readers;
   end Reader_Count_Of;

   function Has_Writer (Lock : Async_RWLock) return Boolean is
   begin
      return Lock.State.Writer;
   end Has_Writer;

   function Waiter_Count_Of (Lock : Async_RWLock) return Natural is
   begin
      return Lock.State.Waiters;
   end Waiter_Count_Of;

   function Stats_Of (Lock : Async_RWLock) return Aion.Sync.Primitive_Stats is
   begin
      return Lock.State.Snapshot;
   end Stats_Of;

end Aion.Sync.RWLock;
