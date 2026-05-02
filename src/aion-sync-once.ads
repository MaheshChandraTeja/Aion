--  Generic async once-cell.
--
--  A value may be initialized exactly once. Get returns a Result immediately;
--  Get_Or_Wait returns a Future that completes when Set succeeds.

with Interfaces;
with Aion.Future;
with Aion.Result;
with Aion.Runtime;

package Aion.Sync.Once is

   generic
      type Value_Type is private;
   package Generic_Once is
      package Value_Futures is new Aion.Future.Generic_Future (Value_Type);
      package Value_Results is new Aion.Result.Generic_Result (Value_Type);

      type Once_Cell (Max_Waiters : Positive := 4_096) is limited private;

      function Is_Set (Cell : Once_Cell) return Boolean;
      function Get (Cell : Once_Cell) return Value_Results.Result_Type;

      function Get_Or_Wait
        (Cell    : in out Once_Cell;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "once.wait") return Value_Futures.Future_Handle;

      function Set
        (Cell  : in out Once_Cell;
         Value : Value_Type) return Aion.Sync.Boolean_Results.Result_Type;

      function Cancel_Waiter
        (Cell   : in out Once_Cell;
         Future : Value_Futures.Future_Handle;
         Reason : String := "once waiter cancelled")
         return Aion.Sync.Boolean_Results.Result_Type;

      function Waiter_Count_Of (Cell : Once_Cell) return Natural;
      function Stats_Of (Cell : Once_Cell) return Aion.Sync.Primitive_Stats;

   private
      type Future_Array is array (Positive range <>) of Value_Futures.Future_Handle;

      protected type Once_State (Max_Waiters : Positive) is
         procedure Set_Value
           (Value    : in Value_Type;
            Accepted : out Boolean);

         procedure Request
           (Future   : in Value_Futures.Future_Handle;
            Immediate : out Boolean;
            Value     : out Value_Type;
            Accepted  : out Boolean);

         procedure Pop_Waiter
           (Future : out Value_Futures.Future_Handle;
            Found  : out Boolean);

         procedure Cancel
           (Future   : in Value_Futures.Future_Handle;
            Accepted : out Boolean);

         function Has_Value return Boolean;
         function Stored return Value_Type;
         function Waiters return Natural;
         function Snapshot return Aion.Sync.Primitive_Stats;
      private
         Set_Flag      : Boolean := False;
         Stored_Value  : Value_Type;
         Queue         : Future_Array (1 .. Max_Waiters) :=
           (others => Value_Futures.Null_Future);
         Head          : Positive := 1;
         Tail          : Positive := 1;
         Count         : Natural := 0;
         Wakeups       : Interfaces.Unsigned_64 := 0;
         Acquisitions  : Interfaces.Unsigned_64 := 0;
         Releases      : Interfaces.Unsigned_64 := 0;
         Cancellations : Interfaces.Unsigned_64 := 0;
         Failures      : Interfaces.Unsigned_64 := 0;
      end Once_State;

      type Once_Cell (Max_Waiters : Positive := 4_096) is limited record
         State : Once_State (Max_Waiters);
      end record;
   end Generic_Once;

end Aion.Sync.Once;
