--  Select-like utilities for waiting on a homogeneous set of futures.

with Aion.Future;
with Aion.Result;
with Aion.Types;

package Aion.Selector is
   type Selection is record
      Ready : Boolean := False;
      Index : Natural := 0;
   end record;

   package Selection_Results is new Aion.Result.Generic_Result (Selection);

   generic
      with package Futures is new Aion.Future.Generic_Future (<>);
   package Generic_Select is
      type Future_Array is array (Positive range <>) of Futures.Future_Handle;

      function First_Ready (Items : Future_Array) return Selection_Results.Result_Type;

      function Await_First
        (Items            : Future_Array;
         Timeout          : Aion.Types.Milliseconds := 30_000;
         Poll_Interval_MS : Aion.Types.Milliseconds := 1)
         return Selection_Results.Result_Type;
   end Generic_Select;
end Aion.Selector;
