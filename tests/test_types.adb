with Aion.Types;
with Test_Support;

procedure Test_Types is
begin
   Test_Support.Section ("types");

   Test_Support.Assert
     (Aion.Types.Image (Aion.Types.Runtime_Running) = "running",
      "runtime state image should be stable");

   Test_Support.Assert
     (Aion.Types.Image (Aion.Types.Task_Completed) = "completed",
      "task state image should be stable");

   Test_Support.Assert
     (Aion.Types.Is_Terminal (Aion.Types.Task_Completed),
      "completed task should be terminal");

   Test_Support.Assert
     (not Aion.Types.Is_Terminal (Aion.Types.Task_Pending),
      "pending task should not be terminal");

   Test_Support.Assert
     (Aion.Types.Image (Aion.Types.Milliseconds'(42)) = "42ms",
      "millisecond image should include ms suffix");

   Test_Support.Assert
     (Aion.Types.Image (Aion.Types.Task_Id'(7)) = "7",
      "task id image should not contain leading spaces");

   Test_Support.Pass ("shared types behave correctly");
end Test_Types;
