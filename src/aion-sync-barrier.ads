--  Async reusable barrier.

with Interfaces;
with Aion.Future;
with Aion.Runtime;

package Aion.Sync.Barrier is

   type Barrier_Outcome is record
      Generation : Natural := 0;
      Is_Leader  : Boolean := False;
   end record;

   package Barrier_Futures is new Aion.Future.Generic_Future (Barrier_Outcome);

   type Async_Barrier
     (Parties     : Positive;
      Max_Waiters : Positive) is limited private;

   function Arrive_And_Wait
     (Barrier : in out Async_Barrier;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "barrier.wait") return Barrier_Futures.Future_Handle;

   function Cancel_Waiter
     (Barrier : in out Async_Barrier;
      Future  : Barrier_Futures.Future_Handle;
      Reason  : String := "barrier waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type;

   function Waiting_Of (Barrier : Async_Barrier) return Natural;
   function Generation_Of (Barrier : Async_Barrier) return Natural;
   function Stats_Of (Barrier : Async_Barrier) return Aion.Sync.Primitive_Stats;

private
   type Future_Array is array (Positive range <>) of Barrier_Futures.Future_Handle;

   protected type Barrier_State
     (Parties     : Positive;
      Max_Waiters : Positive) is
      procedure Arrive
        (Future     : in Barrier_Futures.Future_Handle;
         Accepted   : out Boolean;
         Released   : out Boolean;
         Generation : out Natural);

      procedure Pop_Released
        (Future    : out Barrier_Futures.Future_Handle;
         Outcome   : out Barrier_Outcome;
         Found     : out Boolean);

      procedure Cancel
        (Future   : in Barrier_Futures.Future_Handle;
         Accepted : out Boolean);

      function Waiting return Natural;
      function Current_Generation return Natural;
      function Snapshot return Aion.Sync.Primitive_Stats;
   private
      Queue         : Future_Array (1 .. Max_Waiters) :=
        (others => Barrier_Futures.Null_Future);
      Head          : Positive := 1;
      Tail          : Positive := 1;
      Count         : Natural := 0;
      Generation    : Natural := 0;
      Release_Count : Natural := 0;
      Release_Index : Natural := 0;
      Wakeups       : Interfaces.Unsigned_64 := 0;
      Acquisitions  : Interfaces.Unsigned_64 := 0;
      Releases      : Interfaces.Unsigned_64 := 0;
      Cancellations : Interfaces.Unsigned_64 := 0;
      Failures      : Interfaces.Unsigned_64 := 0;
   end Barrier_State;

   type Async_Barrier
     (Parties     : Positive;
      Max_Waiters : Positive) is limited record
      State : Barrier_State (Parties, Max_Waiters);
   end record;

end Aion.Sync.Barrier;
