with Ada.Calendar;
with Interfaces;
with Aion.Config;
with Aion.Runtime;
with Test_Jobs;
with Test_Support;

procedure Test_Runtime_Stress is
   use type Ada.Calendar.Time;
   use type Interfaces.Unsigned_64;

   Job_Count : constant Interfaces.Unsigned_64 := 1_000;

   procedure Wait_For_Count (Target : Interfaces.Unsigned_64) is
      Started : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      while Test_Jobs.Count < Target loop
         exit when Ada.Calendar.Clock - Started > 5.0;
         delay 0.001;
      end loop;
   end Wait_For_Count;

   function Make_Runtime return Aion.Runtime.Runtime_Handle is
      Config : Aion.Config.Runtime_Config := Aion.Config.Default;
   begin
      Config := Aion.Config.With_Name (Config, "stress-test");
      Config := Aion.Config.With_Workers (Config, 4);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 2_048);
      Config := Aion.Config.With_Shutdown_Timeout (Config, 5_000);
      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Start_Result : Aion.Runtime.Operation_Results.Result_Type;
   Stop_Result  : Aion.Runtime.Operation_Results.Result_Type;
   Spawn_Result : Aion.Runtime.Spawn_Results.Result_Type;
   Stats        : Aion.Runtime.Runtime_Stats;
begin
   Test_Support.Section ("runtime stress");
   Test_Jobs.Reset;

   Start_Result := Aion.Runtime.Start (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Start_Result),
      "runtime starts");

   for Index in 1 .. Natural (Job_Count) loop
      Spawn_Result := Aion.Runtime.Spawn
        (Runtime,
         "stress-job-" & Integer'Image (Index),
         Test_Jobs.Increment'Access);
      Test_Support.Assert
        (Aion.Runtime.Spawn_Results.Is_Ok (Spawn_Result),
         "stress spawn succeeds");
   end loop;

   Wait_For_Count (Job_Count);
   Stop_Result := Aion.Runtime.Shutdown (Runtime);

   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Stop_Result),
      "stress runtime shuts down");

   Stats := Aion.Runtime.Stats_Of (Runtime);
   Test_Support.Assert_U64_Equals (Job_Count, Test_Jobs.Count, "all stress jobs ran");
   Test_Support.Assert_U64_Equals (Job_Count, Stats.Completed_Tasks, "all stress jobs completed");
   Test_Support.Assert_U64_Equals (0, Stats.Failed_Tasks, "stress jobs did not fail");

   Test_Support.Pass ("runtime stress works");
end Test_Runtime_Stress;
