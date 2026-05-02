with Aion.Errors;

package body Aion.Selector is
   package body Generic_Select is
      use type Aion.Types.Milliseconds;

      function First_Ready (Items : Future_Array) return Selection_Results.Result_Type is
      begin
         for I in Items'Range loop
            if Futures.Is_Done (Items (I)) then
               return Selection_Results.Success ((Ready => True, Index => I));
            end if;
         end loop;
         return Selection_Results.Success ((Ready => False, Index => 0));
      end First_Ready;

      function To_Duration (Ms : Aion.Types.Milliseconds) return Duration is
      begin
         return Duration (Long_Float (Ms) / 1_000.0);
      end To_Duration;

      function Await_First
        (Items            : Future_Array;
         Timeout          : Aion.Types.Milliseconds := 30_000;
         Poll_Interval_MS : Aion.Types.Milliseconds := 1)
         return Selection_Results.Result_Type is
         Elapsed : Aion.Types.Milliseconds := 0;
         Probe   : Selection_Results.Result_Type;
      begin
         loop
            Probe := First_Ready (Items);
            if Selection_Results.Value (Probe).Ready then
               return Probe;
            end if;

            if Elapsed >= Timeout then
               return Selection_Results.Failure
                 (Aion.Errors.Timeout,
                  "select await timed out", "Aion.Selector.Await_First");
            end if;

            delay To_Duration (Poll_Interval_MS);
            Elapsed := Elapsed + Poll_Interval_MS;
         end loop;
      end Await_First;
   end Generic_Select;
end Aion.Selector;
