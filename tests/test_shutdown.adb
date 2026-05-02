with Ada.Calendar;
with Interfaces;
with Aion.Config;
with Aion.Runtime;
with Aion.Types;
with Test_Jobs;
with Test_Support;

procedure Test_Shutdown is
   use type Ada.Calendar.Time;
   use type Interfaces.Unsigned_64;

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
      Config := Aion.Config.With_Name (Config, "shutdown-test");
      Config := Aion.Config.With_Workers (Config, 2);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 32);
      Config := Aion.Config.With_Shutdown_Mode (Config, Aion.Types.Shutdown_Graceful);
      Config := Aion.Config.With_Shutdown_Timeout (Config, 3_000);
      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Start_Result : Aion.Runtime.Operation_Results.Result_Type;
   Stop_Result  : Aion.Runtime.Operation_Results.Result_Type;
   Spawn_Result : Aion.Runtime.Spawn_Results.Result_Type;
   Stats        : Aion.Runtime.Runtime_Stats;
begin
   Test_Support.Section ("shutdown");
   Test_Jobs.Reset;

   Start_Result := Aion.Runtime.Start (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Start_Result),
      "runtime starts");

   for Index in 1 .. 10 loop
      Spawn_Result := Aion.Runtime.Spawn
        (Runtime,
         "slow-job-" & Integer'Image (Index),
         Test_Jobs.Slow_Increment'Access);
      Test_Support.Assert
        (Aion.Runtime.Spawn_Results.Is_Ok (Spawn_Result),
         "slow job spawn succeeds");
   end loop;

   Wait_For_Count (10);
   Stop_Result := Aion.Runtime.Shutdown (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Stop_Result),
      "graceful shutdown succeeds");

   Stats := Aion.Runtime.Stats_Of (Runtime);
   Test_Support.Assert_U64_Equals (10, Stats.Completed_Tasks, "shutdown waits for queued work");
   Test_Support.Assert (Aion.Runtime.Is_Stopped (Runtime), "runtime reports stopped");

   Test_Support.Pass ("shutdown works");
end Test_Shutdown;
