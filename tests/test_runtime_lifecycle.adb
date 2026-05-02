with Ada.Calendar;
with Interfaces;
with Aion.Config;
with Aion.Runtime;
with Aion.Types;
with Test_Jobs;
with Test_Support;

procedure Test_Runtime_Lifecycle is
   use type Ada.Calendar.Time;
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Runtime_State;

   procedure Wait_For_Count (Target : Interfaces.Unsigned_64) is
      Started : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      while Test_Jobs.Count < Target loop
         exit when Ada.Calendar.Clock - Started > 2.0;
         delay 0.001;
      end loop;
   end Wait_For_Count;

   function Make_Runtime return Aion.Runtime.Runtime_Handle is
      Config : Aion.Config.Runtime_Config := Aion.Config.Default;
   begin
      Config := Aion.Config.With_Name (Config, "lifecycle-test");
      Config := Aion.Config.With_Workers (Config, 2);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 64);
      Config := Aion.Config.With_Shutdown_Timeout (Config, 2_000);
      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Start_Result : Aion.Runtime.Operation_Results.Result_Type;
   Stop_Result  : Aion.Runtime.Operation_Results.Result_Type;
   Spawn_Result : Aion.Runtime.Spawn_Results.Result_Type;
   Stats        : Aion.Runtime.Runtime_Stats;
begin
   Test_Support.Section ("runtime lifecycle");
   Test_Jobs.Reset;

   Test_Support.Assert
     (Aion.Runtime.State_Of (Runtime) = Aion.Types.Runtime_Created,
      "runtime starts in created state");

   Start_Result := Aion.Runtime.Start (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Start_Result),
      "runtime starts successfully");
   Test_Support.Assert (Aion.Runtime.Is_Running (Runtime), "runtime is running");

   for Index in 1 .. 5 loop
      Spawn_Result := Aion.Runtime.Spawn
        (Runtime,
         "increment-" & Integer'Image (Index),
         Test_Jobs.Increment'Access);
      Test_Support.Assert
        (Aion.Runtime.Spawn_Results.Is_Ok (Spawn_Result),
         "spawn succeeds");
   end loop;

   Wait_For_Count (5);
   Test_Support.Assert_U64_Equals (5, Test_Jobs.Count, "all lifecycle jobs ran");

   Stop_Result := Aion.Runtime.Shutdown (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Stop_Result),
      "runtime shuts down successfully");
   Test_Support.Assert
     (Aion.Runtime.State_Of (Runtime) = Aion.Types.Runtime_Stopped,
      "runtime reaches stopped state");

   Stats := Aion.Runtime.Stats_Of (Runtime);
   Test_Support.Assert_U64_Equals (5, Stats.Completed_Tasks, "completed task count");
   Test_Support.Pass ("runtime lifecycle works");
end Test_Runtime_Lifecycle;
