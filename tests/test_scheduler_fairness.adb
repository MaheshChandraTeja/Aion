with Ada.Calendar;
with Interfaces;
with Aion.Config;
with Aion.Runtime;
with Test_Jobs;
with Test_Support;

procedure Test_Scheduler_Fairness is
   use type Ada.Calendar.Time;
   use type Interfaces.Unsigned_64;

   Job_Count : constant Interfaces.Unsigned_64 := 100;

   procedure Wait_For_Count (Target : Interfaces.Unsigned_64) is
      Started : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      while Test_Jobs.Count < Target loop
         exit when Ada.Calendar.Clock - Started > 3.0;
         delay 0.001;
      end loop;
   end Wait_For_Count;

   function Make_Runtime return Aion.Runtime.Runtime_Handle is
      Config : Aion.Config.Runtime_Config := Aion.Config.Default;
   begin
      Config := Aion.Config.With_Name (Config, "fairness-test");
      Config := Aion.Config.With_Workers (Config, 4);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 256);
      Config := Aion.Config.With_Shutdown_Timeout (Config, 3_000);
      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Ignored_Start : Aion.Runtime.Operation_Results.Result_Type;
   Ignored_Stop  : Aion.Runtime.Operation_Results.Result_Type;
   Spawn_Result  : Aion.Runtime.Spawn_Results.Result_Type;
   Stats         : Aion.Runtime.Runtime_Stats;
begin
   Test_Support.Section ("scheduler fairness");
   Test_Jobs.Reset;

   Ignored_Start := Aion.Runtime.Start (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Ignored_Start),
      "runtime starts");

   for Index in 1 .. Natural (Job_Count) loop
      Spawn_Result := Aion.Runtime.Spawn
        (Runtime,
         "fairness-job-" & Integer'Image (Index),
         Test_Jobs.Yielding_Increment'Access);
      Test_Support.Assert
        (Aion.Runtime.Spawn_Results.Is_Ok (Spawn_Result),
         "fairness spawn succeeds");
   end loop;

   Wait_For_Count (Job_Count);
   Ignored_Stop := Aion.Runtime.Shutdown (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Ignored_Stop),
      "runtime stops");

   Stats := Aion.Runtime.Stats_Of (Runtime);
   Test_Support.Assert_U64_Equals (Job_Count, Test_Jobs.Count, "all fairness jobs ran");
   Test_Support.Assert_U64_Equals (Job_Count, Stats.Completed_Tasks, "all fairness jobs completed");

   Test_Support.Pass ("scheduler runs many yielded jobs fairly enough for Module 2");
end Test_Scheduler_Fairness;
