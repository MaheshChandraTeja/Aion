--  Async counting semaphore.

with Interfaces;
with Aion.Future;
with Aion.Result;
with Aion.Runtime;

package Aion.Sync.Semaphore is

   type Permit_Token is new Interfaces.Unsigned_64;

   type Permit_Guard is record
      Token : Permit_Token := 0;
      Valid : Boolean := False;
   end record;

   package Permit_Futures is new Aion.Future.Generic_Future (Permit_Guard);
   package Permit_Results is new Aion.Result.Generic_Result (Permit_Guard);

   type Async_Semaphore
     (Initial_Permits : Natural := 1;
      Maximum_Permits : Positive := 1;
      Max_Waiters     : Positive := 4_096) is limited private;

   function Acquire
     (Semaphore : in out Async_Semaphore;
      Runtime   : access Aion.Runtime.Runtime_Handle := null;
      Name      : String := "semaphore.acquire") return Permit_Futures.Future_Handle;

   function Try_Acquire
     (Semaphore : in out Async_Semaphore) return Permit_Results.Result_Type;

   function Release
     (Semaphore : in out Async_Semaphore;
      Permit    : in out Permit_Guard) return Aion.Sync.Boolean_Results.Result_Type;

   function Cancel_Waiter
     (Semaphore : in out Async_Semaphore;
      Future    : Permit_Futures.Future_Handle;
      Reason    : String := "semaphore waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type;

   function Available_Of (Semaphore : Async_Semaphore) return Natural;
   function Waiter_Count_Of (Semaphore : Async_Semaphore) return Natural;
   function Stats_Of (Semaphore : Async_Semaphore) return Aion.Sync.Primitive_Stats;

private
   type Future_Array is array (Positive range <>) of Permit_Futures.Future_Handle;

   protected type Semaphore_State
     (Initial_Permits : Natural;
      Maximum_Permits : Positive;
      Max_Waiters     : Positive) is

      procedure Request
        (Future    : in Permit_Futures.Future_Handle;
         Immediate : out Boolean;
         Permit    : out Permit_Guard;
         Accepted  : out Boolean);

      procedure Try_Request
        (Accepted : out Boolean;
         Permit   : out Permit_Guard);

      procedure Release_One
        (Accepted : out Boolean;
         Next     : out Permit_Futures.Future_Handle;
         Permit   : out Permit_Guard;
         Has_Next : out Boolean);

      procedure Cancel
        (Future   : in Permit_Futures.Future_Handle;
         Accepted : out Boolean);

      function Available return Natural;
      function Waiters return Natural;
      function Snapshot return Aion.Sync.Primitive_Stats;
   private
      Free          : Natural := Initial_Permits;
      Next_Token    : Permit_Token := 1;
      Queue         : Future_Array (1 .. Max_Waiters) :=
        (others => Permit_Futures.Null_Future);
      Head          : Positive := 1;
      Tail          : Positive := 1;
      Count         : Natural := 0;
      Wakeups       : Interfaces.Unsigned_64 := 0;
      Acquisitions  : Interfaces.Unsigned_64 := 0;
      Releases      : Interfaces.Unsigned_64 := 0;
      Cancellations : Interfaces.Unsigned_64 := 0;
      Failures      : Interfaces.Unsigned_64 := 0;
   end Semaphore_State;

   type Async_Semaphore
     (Initial_Permits : Natural := 1;
      Maximum_Permits : Positive := 1;
      Max_Waiters     : Positive := 4_096) is limited record
      State : Semaphore_State (Initial_Permits, Maximum_Permits, Max_Waiters);
   end record;

end Aion.Sync.Semaphore;
