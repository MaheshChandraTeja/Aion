with Ada.Calendar;
use type Ada.Calendar.Time;
with Ada.Text_IO;
with Aion.Config;
with Aion.Runtime;
with Aion_Example_Jobs;

procedure Runtime_Core_Demo is
   procedure Wait_For_Count (Target : Natural) is
      Started : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      while Aion_Example_Jobs.Count < Target loop
         exit when Ada.Calendar.Clock - Started > 2.0;
         delay 0.001;
      end loop;
   end Wait_For_Count;

   function Make_Runtime return Aion.Runtime.Runtime_Handle is
      Config : Aion.Config.Runtime_Config := Aion.Config.Default;
   begin
      Config := Aion.Config.With_Name (Config, "aion-runtime-demo");
      Config := Aion.Config.With_Workers (Config, 4);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 128);
      Config := Aion.Config.With_Shutdown_Timeout (Config, 2_000);
      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Start_Result : Aion.Runtime.Operation_Results.Result_Type;
   Stop_Result  : Aion.Runtime.Operation_Results.Result_Type;
   Spawn_Result : Aion.Runtime.Spawn_Results.Result_Type;
   Stats        : Aion.Runtime.Runtime_Stats;
begin
   Aion_Example_Jobs.Reset;

   Start_Result := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Start_Result) then
      Ada.Text_IO.Put_Line ("runtime failed to start");
      return;
   end if;

   Spawn_Result := Aion.Runtime.Spawn
     (Runtime, "heartbeat", Aion_Example_Jobs.Print_Heartbeat'Access);
   if Aion.Runtime.Spawn_Results.Is_Err (Spawn_Result) then
      Ada.Text_IO.Put_Line ("heartbeat spawn failed");
   end if;

   for Index in 1 .. 10 loop
      Spawn_Result := Aion.Runtime.Spawn
        (Runtime,
         "increment-" & Integer'Image (Index),
         Aion_Example_Jobs.Increment'Access);

      if Aion.Runtime.Spawn_Results.Is_Err (Spawn_Result) then
         Ada.Text_IO.Put_Line ("increment spawn failed");
      end if;
   end loop;

   Spawn_Result := Aion.Runtime.Spawn
     (Runtime, "fault-isolated", Aion_Example_Jobs.Faulting'Access);
   if Aion.Runtime.Spawn_Results.Is_Err (Spawn_Result) then
      Ada.Text_IO.Put_Line ("faulting spawn failed");
   end if;

   Wait_For_Count (10);
   Stop_Result := Aion.Runtime.Shutdown (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Stop_Result) then
      Ada.Text_IO.Put_Line ("runtime shutdown reported failure");
   end if;

   Stats := Aion.Runtime.Stats_Of (Runtime);
   Ada.Text_IO.Put_Line (Aion.Runtime.Image (Stats));
end Runtime_Core_Demo;
