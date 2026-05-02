with Test_Support;
with Aion.Config;
with Aion.Diagnostics;
with Aion.Runtime;

procedure Test_Diagnostics is
   use type Aion.Diagnostics.Health_Status;
   Config : constant Aion.Config.Runtime_Config :=
     Aion.Config.With_Workers (Aion.Config.Default, 1);
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create (Config);
   Health : Aion.Diagnostics.Runtime_Health;
   Result : Aion.Diagnostics.Operation_Results.Result_Type;
begin
   Test_Support.Section ("diagnostics");
   Health := Aion.Diagnostics.Inspect_Runtime (Runtime);
   Test_Support.Assert (Health.Status = Aion.Diagnostics.Health_Good, "fresh runtime should be healthy");
   Result := Aion.Diagnostics.Validate_Runtime (Runtime);
   Test_Support.Assert (Aion.Diagnostics.Operation_Results.Is_Ok (Result), "runtime diagnostics should validate default runtime");
   Test_Support.Assert (Aion.Diagnostics.Report (Runtime)'Length > 0, "runtime report should be populated");
   Test_Support.Pass ("diagnostics health inspection works");
end Test_Diagnostics;
