with Aion.Runtime;
with Interfaces;
with Test_Support;
with Aion.Test_Support;

procedure Test_Test_Support is
   use type Interfaces.Unsigned_64;
   Counter : Aion.Test_Support.Atomic_Counter;
   Harness : Aion.Test_Support.Runtime_Harness;
   Result  : Aion.Runtime.Operation_Results.Result_Type;
begin
   Test_Support.Section ("public test support");
   Counter.Increment;
   Counter.Add (4);
   Test_Support.Assert (Counter.Value = 5, "atomic counter should add deterministically");
   Counter.Reset;
   Test_Support.Assert (Counter.Value = 0, "atomic counter reset should clear state");

   Aion.Test_Support.Initialize (Harness);
   Result := Aion.Test_Support.Start (Harness);
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (Result), "runtime harness should start runtime");
   Result := Aion.Test_Support.Shutdown (Harness);
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (Result), "runtime harness should shut down runtime");
   Test_Support.Pass ("public test support works");
end Test_Test_Support;
