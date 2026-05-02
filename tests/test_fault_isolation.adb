with Ada.Calendar;
with Interfaces;
with Aion.Config;
with Aion.Runtime;
with Aion.Task_Handle;
with Aion.Types;
with Test_Jobs;
with Test_Support;

procedure Test_Fault_Isolation is
   use type Ada.Calendar.Time;
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Task_State;

   procedure Wait_For
     (Target_Count  : Interfaces.Unsigned_64;
      Target_Faults : Interfaces.Unsigned_64) is
      Started : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      while Test_Jobs.Count < Target_Count or else Test_Jobs.Fault_Count < Target_Faults loop
         exit when Ada.Calendar.Clock - Started > 3.0;
         delay 0.001;
      end loop;
   end Wait_For;

   function Make_Runtime return Aion.Runtime.Runtime_Handle is
      Config : Aion.Config.Runtime_Config := Aion.Config.Default;
   begin
      Config := Aion.Config.With_Name (Config, "fault-isolation-test");
      Config := Aion.Config.With_Workers (Config, 2);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 32);
      Config := Aion.Config.With_Shutdown_Timeout (Config, 3_000);
      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Start_Result : Aion.Runtime.Operation_Results.Result_Type;
   Stop_Result  : Aion.Runtime.Operation_Results.Result_Type;
   Fault_Result : Aion.Runtime.Spawn_Results.Result_Type;
   Good_Result  : Aion.Runtime.Spawn_Results.Result_Type;
   Fault_Handle : Aion.Task_Handle.Task_Handle;
   Stats        : Aion.Runtime.Runtime_Stats;
begin
   Test_Support.Section ("fault isolation");
   Test_Jobs.Reset;

   Start_Result := Aion.Runtime.Start (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Start_Result),
      "runtime starts");

   Fault_Result := Aion.Runtime.Spawn
     (Runtime,
      "faulting-job",
      Test_Jobs.Faulting'Access);
   Test_Support.Assert
     (Aion.Runtime.Spawn_Results.Is_Ok (Fault_Result),
      "faulting job spawns");
   Fault_Handle := Aion.Runtime.Spawn_Results.Value (Fault_Result);

   Good_Result := Aion.Runtime.Spawn
     (Runtime,
      "good-job-after-fault",
      Test_Jobs.Increment'Access);
   Test_Support.Assert
     (Aion.Runtime.Spawn_Results.Is_Ok (Good_Result),
      "good job spawns after faulting job");

   Wait_For (1, 1);
   Stop_Result := Aion.Runtime.Shutdown (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Stop_Result),
      "runtime still shuts down after job exception");

   Stats := Aion.Runtime.Stats_Of (Runtime);
   Test_Support.Assert_U64_Equals (1, Stats.Failed_Tasks, "one task failed");
   Test_Support.Assert_U64_Equals (1, Stats.Completed_Tasks, "one task completed despite failure");
   Test_Support.Assert
     (Aion.Task_Handle.State_Of (Fault_Handle) = Aion.Types.Task_Faulted,
      "faulting handle observes faulted state");

   Test_Support.Pass ("task failure is isolated from runtime");
end Test_Fault_Isolation;
