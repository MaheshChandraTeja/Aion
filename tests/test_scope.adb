with Test_Support;
with Test_Cancellation_Jobs;
with Aion.Runtime;
with Aion.Scope;

procedure Test_Scope is
   Runtime : aliased Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Scope   : Aion.Scope.Scope_Handle (4);
   R       : Aion.Runtime.Operation_Results.Result_Type;
   S       : Aion.Runtime.Spawn_Results.Result_Type;
   C       : Aion.Scope.Operation_Results.Result_Type;
begin
   Test_Support.Section ("scope");

   Test_Cancellation_Jobs.Reset;

   R := Aion.Runtime.Start (Runtime);
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (R), "runtime start");

   Aion.Scope.Open (Scope, Runtime'Unchecked_Access, "scope-test");

   S := Aion.Scope.Spawn
     (Scope,
      "scoped-quick",
      Test_Cancellation_Jobs.Quick_Job'Access);
   Test_Support.Assert (Aion.Runtime.Spawn_Results.Is_Ok (S), "scope spawn");

   C := Aion.Scope.Close (Scope, Timeout => 2_000);
   Test_Support.Assert (Aion.Scope.Operation_Results.Is_Ok (C), "scope close");
   Test_Support.Assert
     (Test_Cancellation_Jobs.Quick_Count >= 1,
      "scoped job should execute");

   R := Aion.Runtime.Shutdown (Runtime);
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (R), "shutdown");

   Test_Support.Pass ("scope opens, spawns, joins, and closes deterministically");
end Test_Scope;
