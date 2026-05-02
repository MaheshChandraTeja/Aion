--  Async reader/writer lock with writer preference.

with Interfaces;
with Aion.Future;
with Aion.Result;
with Aion.Runtime;

package Aion.Sync.RWLock is

   type Guard_Kind is (Read_Guard, Write_Guard);
   type Guard_Token is new Interfaces.Unsigned_64;

   type RW_Guard is record
      Token : Guard_Token := 0;
      Kind  : Guard_Kind := Read_Guard;
      Valid : Boolean := False;
   end record;

   package Guard_Futures is new Aion.Future.Generic_Future (RW_Guard);
   package Guard_Results is new Aion.Result.Generic_Result (RW_Guard);

   type Async_RWLock (Max_Waiters : Positive := 4_096) is limited private;

   function Read_Lock
     (Lock    : in out Async_RWLock;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "rwlock.read") return Guard_Futures.Future_Handle;

   function Write_Lock
     (Lock    : in out Async_RWLock;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "rwlock.write") return Guard_Futures.Future_Handle;

   function Try_Read_Lock
     (Lock : in out Async_RWLock) return Guard_Results.Result_Type;

   function Try_Write_Lock
     (Lock : in out Async_RWLock) return Guard_Results.Result_Type;

   function Unlock
     (Lock  : in out Async_RWLock;
      Guard : in out RW_Guard) return Aion.Sync.Boolean_Results.Result_Type;

   function Cancel_Waiter
     (Lock   : in out Async_RWLock;
      Future : Guard_Futures.Future_Handle;
      Reason : String := "rwlock waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type;

   function Reader_Count_Of (Lock : Async_RWLock) return Natural;
   function Has_Writer (Lock : Async_RWLock) return Boolean;
   function Waiter_Count_Of (Lock : Async_RWLock) return Natural;
   function Stats_Of (Lock : Async_RWLock) return Aion.Sync.Primitive_Stats;

private
   type Wait_Kind is (Waiting_Read, Waiting_Write);

   type Wait_Item is record
      Kind   : Wait_Kind := Waiting_Read;
      Future : Guard_Futures.Future_Handle := Guard_Futures.Null_Future;
   end record;

   type Wait_Array is array (Positive range <>) of Wait_Item;

   protected type RWLock_State (Max_Waiters : Positive) is
      procedure Request
        (Kind      : in Wait_Kind;
         Future    : in Guard_Futures.Future_Handle;
         Immediate : out Boolean;
         Guard     : out RW_Guard;
         Accepted  : out Boolean);

      procedure Try_Request
        (Kind     : in Wait_Kind;
         Accepted : out Boolean;
         Guard    : out RW_Guard);

      procedure Release
        (Guard      : in RW_Guard;
         Accepted   : out Boolean);

      procedure Pop_Ready
        (Future : out Guard_Futures.Future_Handle;
         Guard  : out RW_Guard;
         Found  : out Boolean);

      procedure Cancel
        (Future   : in Guard_Futures.Future_Handle;
         Accepted : out Boolean);

      function Readers return Natural;
      function Writer return Boolean;
      function Waiters return Natural;
      function Snapshot return Aion.Sync.Primitive_Stats;
   private
      Active_Readers : Natural := 0;
      Writer_Active  : Boolean := False;
      Next_Token     : Guard_Token := 1;
      Queue          : Wait_Array (1 .. Max_Waiters);
      Head           : Positive := 1;
      Tail           : Positive := 1;
      Count          : Natural := 0;
      Wakeups        : Interfaces.Unsigned_64 := 0;
      Acquisitions   : Interfaces.Unsigned_64 := 0;
      Releases       : Interfaces.Unsigned_64 := 0;
      Cancellations  : Interfaces.Unsigned_64 := 0;
      Failures       : Interfaces.Unsigned_64 := 0;
   end RWLock_State;

   type Async_RWLock (Max_Waiters : Positive := 4_096) is limited record
      State : RWLock_State (Max_Waiters);
   end record;

end Aion.Sync.RWLock;
