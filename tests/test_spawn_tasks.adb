with Ada.Calendar;
with Interfaces;
with Aion.Config;
with Aion.Runtime;
with Aion.Task_Handle;
with Aion.Types;
with Test_Jobs;
with Test_Support;

procedure Test_Spawn_Tasks is
   use type Ada.Calendar.Time;
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Task_State;

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
      Config := Aion.Config.With_Name (Config, "spawn-test");
      Config := Aion.Config.With_Workers (Config, 2);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 16);
      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Spawn_Result : Aion.Runtime.Spawn_Results.Result_Type;
   Start_Result : Aion.Runtime.Operation_Results.Result_Type;
   Stop_Result  : Aion.Runtime.Operation_Results.Result_Type;
   Handle       : Aion.Task_Handle.Task_Handle;
begin
   Test_Support.Section ("spawn tasks");
   Test_Jobs.Reset;

   --  Spawning before Start is allowed. Jobs remain queued until workers exist.
   Spawn_Result := Aion.Runtime.Spawn
     (Runtime,
      "pre-start-job",
      Test_Jobs.Increment'Access);
   Test_Support.Assert
     (Aion.Runtime.Spawn_Results.Is_Ok (Spawn_Result),
      "spawn before start succeeds");

   Handle := Aion.Runtime.Spawn_Results.Value (Spawn_Result);
   Test_Support.Assert (Aion.Task_Handle.Is_Valid (Handle), "spawn returns a valid handle");
   Test_Support.Assert
     (Aion.Task_Handle.State_Of (Handle) = Aion.Types.Task_Scheduled,
      "pre-start job is scheduled");

   Start_Result := Aion.Runtime.Start (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Start_Result),
      "runtime starts after pre-start spawn");

   Wait_For_Count (1);
   Stop_Result := Aion.Runtime.Shutdown (Runtime);

   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Stop_Result),
      "runtime shuts down");
   Test_Support.Assert_U64_Equals (1, Test_Jobs.Count, "pre-start spawned task executed");
   Test_Support.Assert
     (Aion.Task_Handle.State_Of (Handle) = Aion.Types.Task_Completed,
      "handle observes completion");

   Test_Support.Pass ("task spawning works");
end Test_Spawn_Tasks;
