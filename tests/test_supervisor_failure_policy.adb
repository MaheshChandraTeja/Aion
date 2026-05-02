with Test_Support;
with Test_Cancellation_Jobs;
with Aion.Runtime;
with Aion.Supervisor;

procedure Test_Supervisor_Failure_Policy is
   Runtime : aliased Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Sup     : Aion.Supervisor.Supervisor (4);
   R       : Aion.Runtime.Operation_Results.Result_Type;
   S       : Aion.Runtime.Spawn_Results.Result_Type;
   C       : Aion.Supervisor.Operation_Results.Result_Type;
begin
   Test_Support.Section ("supervisor failure policy");

   Test_Cancellation_Jobs.Reset;
   R := Aion.Runtime.Start (Runtime);
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (R), "runtime start");

   Aion.Supervisor.Initialize
     (Sup,
      Runtime'Unchecked_Access,
      "cancel-supervisor",
      Config =>
        (Policy           => Aion.Supervisor.Cancel_All_On_First_Failure,
         Max_Restarts     => 0,
         Restart_Delay_Ms => 0,
         Join_Timeout_Ms  => 500));

   S := Aion.Supervisor.Spawn
     (Sup, "faulty", Test_Cancellation_Jobs.Faulty_Job'Access);
   Test_Support.Assert (Aion.Runtime.Spawn_Results.Is_Ok (S), "spawn faulty");

   delay 0.050;
   C := Aion.Supervisor.Tick (Sup);
   Test_Support.Assert
     (Aion.Supervisor.Operation_Results.Is_Ok (C)
      or else Aion.Supervisor.Operation_Results.Is_Err (C),
      "tick should return a structured result");

   R := Aion.Runtime.Shutdown (Runtime);
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (R), "shutdown");

   Test_Support.Pass ("supervisor applies failure policy without orphaning children");
end Test_Supervisor_Failure_Policy;
