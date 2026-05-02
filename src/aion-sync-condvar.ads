--  Async condition variable.
--
--  This primitive only models notification. Pair it with Aion.Sync.Mutex or
--  another state guard in caller code.

with Interfaces;
with Aion.Runtime;

package Aion.Sync.Condvar is

   package Wait_Futures renames Aion.Sync.Boolean_Futures;

   type Async_Condvar (Max_Waiters : Positive := 4_096) is limited private;

   function Wait
     (Condvar : in out Async_Condvar;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "condvar.wait") return Wait_Futures.Future_Handle;

   procedure Notify_One (Condvar : in out Async_Condvar);
   procedure Notify_All (Condvar : in out Async_Condvar);

   function Cancel_Waiter
     (Condvar : in out Async_Condvar;
      Future  : Wait_Futures.Future_Handle;
      Reason  : String := "condvar waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type;

   function Waiter_Count_Of (Condvar : Async_Condvar) return Natural;
   function Stats_Of (Condvar : Async_Condvar) return Aion.Sync.Primitive_Stats;

private
   type Future_Array is array (Positive range <>) of Wait_Futures.Future_Handle;

   protected type Condvar_State (Max_Waiters : Positive) is
      procedure Enqueue
        (Future   : in Wait_Futures.Future_Handle;
         Accepted : out Boolean);

      procedure Pop_One
        (Future : out Wait_Futures.Future_Handle;
         Found  : out Boolean);

      procedure Cancel
        (Future   : in Wait_Futures.Future_Handle;
         Accepted : out Boolean);

      function Waiters return Natural;
      function Snapshot return Aion.Sync.Primitive_Stats;
   private
      Queue         : Future_Array (1 .. Max_Waiters) :=
        (others => Wait_Futures.Null_Future);
      Head          : Positive := 1;
      Tail          : Positive := 1;
      Count         : Natural := 0;
      Wakeups       : Interfaces.Unsigned_64 := 0;
      Acquisitions  : Interfaces.Unsigned_64 := 0;
      Releases      : Interfaces.Unsigned_64 := 0;
      Cancellations : Interfaces.Unsigned_64 := 0;
      Failures      : Interfaces.Unsigned_64 := 0;
   end Condvar_State;

   type Async_Condvar (Max_Waiters : Positive := 4_096) is limited record
      State : Condvar_State (Max_Waiters);
   end record;

end Aion.Sync.Condvar;
