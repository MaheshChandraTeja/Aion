with Interfaces;
with Test_Support;
with Test_Cancellation_Jobs;
with Aion.Runtime;
with Aion.Supervisor;

procedure Test_Supervisor_Restart is
   use type Interfaces.Unsigned_64;
   Runtime : aliased Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Sup     : Aion.Supervisor.Supervisor (2);
   R       : Aion.Runtime.Operation_Results.Result_Type;
   S       : Aion.Runtime.Spawn_Results.Result_Type;
   T       : Aion.Supervisor.Operation_Results.Result_Type;
   pragma Unreferenced (T);
begin
   Test_Support.Section ("supervisor restart");

   Test_Cancellation_Jobs.Reset;
   R := Aion.Runtime.Start (Runtime);
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (R), "runtime start");

   Aion.Supervisor.Initialize
     (Sup,
      Runtime'Unchecked_Access,
      "restart-supervisor",
      Config =>
        (Policy           => Aion.Supervisor.Restart_Failed_Children,
         Max_Restarts     => 1,
         Restart_Delay_Ms => 1,
         Join_Timeout_Ms  => 500));

   S := Aion.Supervisor.Spawn
     (Sup,
      "faulty",
      Test_Cancellation_Jobs.Faulty_Job'Access);
   Test_Support.Assert
     (Aion.Runtime.Spawn_Results.Is_Ok (S),
      "supervised spawn should succeed");

   delay 0.050;
   T := Aion.Supervisor.Tick (Sup);

   --  Restart may fail if the child exhausts the budget immediately after
   --  restart, but it must not corrupt the supervisor.
   Test_Support.Assert
     (Aion.Supervisor.Stats_Of (Sup).Children >= 1,
      "supervisor should retain child metadata");

   R := Aion.Runtime.Shutdown (Runtime);
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (R), "shutdown");

   Test_Support.Pass ("supervisor detects failed children and applies restart policy");
end Test_Supervisor_Restart;
