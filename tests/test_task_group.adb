with Test_Support;
with Test_Cancellation_Jobs;
with Aion.Runtime;
with Aion.Task_Group;

procedure Test_Task_Group is
   Runtime : aliased Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Group   : Aion.Task_Group.Task_Group (8);
   Started : Aion.Runtime.Operation_Results.Result_Type;
   Spawned : Aion.Runtime.Spawn_Results.Result_Type;
   Joined  : Aion.Task_Group.Operation_Results.Result_Type;
   Stopped : Aion.Runtime.Operation_Results.Result_Type;
begin
   Test_Support.Section ("task group");

   Test_Cancellation_Jobs.Reset;
   Started := Aion.Runtime.Start (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Started),
      "runtime should start");

   Aion.Task_Group.Initialize (Group, Runtime'Unchecked_Access, "test-group");

   for I in 1 .. 4 loop
      Spawned := Aion.Task_Group.Spawn
        (Group,
         "quick",
         Test_Cancellation_Jobs.Quick_Job'Access);
      Test_Support.Assert
        (Aion.Runtime.Spawn_Results.Is_Ok (Spawned),
         "group spawn should succeed");
   end loop;

   Joined := Aion.Task_Group.Join_All (Group, Timeout => 2_000);
   Test_Support.Assert
     (Aion.Task_Group.Operation_Results.Is_Ok (Joined),
      "task group should join all tasks");
   Test_Support.Assert
     (Test_Cancellation_Jobs.Quick_Count >= 4,
      "quick jobs should run");

   Stopped := Aion.Runtime.Shutdown (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Stopped),
      "runtime shutdown should succeed");

   Test_Support.Pass ("task group spawns and joins runtime tasks");
end Test_Task_Group;
