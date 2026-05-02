--  Async synchronization common types and counters for Aion.
--
--  This parent package intentionally stays small. Child packages provide the
--  concrete async-aware primitives, while this package centralizes shared
--  statistics, boolean futures, and protected counters.

with Interfaces;
with Aion.Future;
with Aion.Result;

package Aion.Sync is
   type Waiter_Count is new Natural;

   type Primitive_Stats is record
      Waiters        : Natural := 0;
      Wakeups        : Interfaces.Unsigned_64 := 0;
      Acquisitions   : Interfaces.Unsigned_64 := 0;
      Releases       : Interfaces.Unsigned_64 := 0;
      Cancellations  : Interfaces.Unsigned_64 := 0;
      Failures       : Interfaces.Unsigned_64 := 0;
   end record;

   package Boolean_Futures is new Aion.Future.Generic_Future (Boolean);
   package Boolean_Results is new Aion.Result.Generic_Result (Boolean);

   protected type Atomic_Counter is
      procedure Increment;
      procedure Add (Amount : Interfaces.Unsigned_64);
      procedure Decrement;
      procedure Reset (To : Interfaces.Unsigned_64 := 0);
      function Value return Interfaces.Unsigned_64;
   private
      Current : Interfaces.Unsigned_64 := 0;
   end Atomic_Counter;

   function Image (Stats : Primitive_Stats) return String;

end Aion.Sync;
