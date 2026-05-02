--  Async mutex primitive.

with Interfaces;
with Aion.Future;
with Aion.Result;
with Aion.Runtime;

package Aion.Sync.Mutex is

   type Lock_Token is new Interfaces.Unsigned_64;

   type Lock_Guard is record
      Token : Lock_Token := 0;
      Valid : Boolean := False;
   end record;

   package Lock_Futures is new Aion.Future.Generic_Future (Lock_Guard);
   package Guard_Results is new Aion.Result.Generic_Result (Lock_Guard);

   type Async_Mutex (Max_Waiters : Positive := 4_096) is limited private;

   function Lock
     (Mutex   : in out Async_Mutex;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "mutex.lock") return Lock_Futures.Future_Handle;

   function Try_Lock
     (Mutex : in out Async_Mutex) return Guard_Results.Result_Type;

   function Unlock
     (Mutex : in out Async_Mutex;
      Guard : in out Lock_Guard) return Aion.Sync.Boolean_Results.Result_Type;

   function Cancel_Waiter
     (Mutex  : in out Async_Mutex;
      Future : Lock_Futures.Future_Handle;
      Reason : String := "mutex waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type;

   function Is_Locked (Mutex : Async_Mutex) return Boolean;
   function Waiter_Count_Of (Mutex : Async_Mutex) return Natural;
   function Stats_Of (Mutex : Async_Mutex) return Aion.Sync.Primitive_Stats;

private
   type Future_Array is array (Positive range <>) of Lock_Futures.Future_Handle;

   protected type Mutex_State (Max_Waiters : Positive) is
      procedure Request_Lock
        (Future   : in Lock_Futures.Future_Handle;
         Immediate : out Boolean;
         Guard     : out Lock_Guard;
         Accepted  : out Boolean);

      procedure Try_Request
        (Accepted : out Boolean;
         Guard    : out Lock_Guard);

      procedure Release
        (Token      : in Lock_Token;
         Accepted   : out Boolean;
         Next       : out Lock_Futures.Future_Handle;
         Next_Guard : out Lock_Guard;
         Has_Next   : out Boolean);

      procedure Cancel
        (Future   : in Lock_Futures.Future_Handle;
         Accepted : out Boolean);

      function Locked return Boolean;
      function Waiters return Natural;
      function Snapshot return Aion.Sync.Primitive_Stats;
   private
      Is_Held       : Boolean := False;
      Owner         : Lock_Token := 0;
      Next_Token    : Lock_Token := 1;
      Queue         : Future_Array (1 .. Max_Waiters) :=
        (others => Lock_Futures.Null_Future);
      Head          : Positive := 1;
      Tail          : Positive := 1;
      Count         : Natural := 0;
      Wakeups       : Interfaces.Unsigned_64 := 0;
      Acquisitions  : Interfaces.Unsigned_64 := 0;
      Releases      : Interfaces.Unsigned_64 := 0;
      Cancellations : Interfaces.Unsigned_64 := 0;
      Failures      : Interfaces.Unsigned_64 := 0;
   end Mutex_State;

   type Async_Mutex (Max_Waiters : Positive := 4_096) is limited record
      State : Mutex_State (Max_Waiters);
   end record;

end Aion.Sync.Mutex;
