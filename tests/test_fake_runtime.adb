with Test_Support;
with Aion.Config;
with Aion.Runtime;
with Aion.Test_Support;

procedure Test_Fake_Runtime is
   use type Aion.Test_Support.Runtime_Access;
   Harness : Aion.Test_Support.Runtime_Harness;
   Config  : constant Aion.Config.Runtime_Config :=
     Aion.Config.With_Max_Queue_Depth
       (Aion.Config.With_Workers (Aion.Config.Default, 1), 64);
   Runtime : Aion.Test_Support.Runtime_Access;
begin
   Test_Support.Section ("fake runtime harness");
   Aion.Test_Support.Initialize (Harness, Config);
   Runtime := Aion.Test_Support.Runtime_Of (Harness);
   Test_Support.Assert (Runtime /= null, "harness should expose runtime access");
   Test_Support.Assert (Aion.Runtime.Stats_Of (Runtime.all).Queue_Capacity = 64,
                        "harness should preserve configured queue capacity");
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (Aion.Test_Support.Shutdown (Harness)),
                        "harness shutdown should succeed");
   Test_Support.Pass ("fake runtime harness works");
end Test_Fake_Runtime;
