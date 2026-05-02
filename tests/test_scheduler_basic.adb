with Aion.Scheduler;
with Aion.Task_Handle;
with Aion.Types;
with Test_Jobs;
with Test_Support;

procedure Test_Scheduler_Basic is
   use type Aion.Types.Task_Id;
   Queue    : Aion.Scheduler.Job_Queue (Max_Capacity => 2);
   Handle   : constant Aion.Task_Handle.Task_Handle :=
     Aion.Task_Handle.Create (1, "scheduler-job");
   Job      : constant Aion.Scheduler.Job_Item :=
     Aion.Scheduler.Make_Job (Handle, Test_Jobs.Increment'Access);
   Taken    : Aion.Scheduler.Job_Item;
   Accepted : Boolean := False;
   Found    : Boolean := False;
begin
   Test_Support.Section ("scheduler basic");

   Queue.Try_Enqueue (Job, Accepted);
   Test_Support.Assert (Accepted, "scheduler accepts valid job");
   Test_Support.Assert (Queue.Depth = 1, "queue depth increments");

   Queue.Take (Taken, Found);
   Test_Support.Assert (Found, "scheduler returns queued job");
   Test_Support.Assert (Aion.Scheduler.Is_Valid (Taken), "taken job is valid");
   Test_Support.Assert
     (Aion.Task_Handle.Id_Of (Aion.Scheduler.Handle_Of (Taken)) = 1,
      "taken job preserves handle id");
   Test_Support.Assert (Queue.Depth = 0, "queue depth decrements");

   Queue.Request_Stop;
   Queue.Take (Taken, Found);
   Test_Support.Assert (not Found, "stopped empty queue wakes takers");

   Test_Support.Pass ("scheduler basic queue works");
end Test_Scheduler_Basic;
