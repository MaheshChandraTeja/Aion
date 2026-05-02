with Ada.Text_IO;
with Aion.Block_On;
with Aion.Config;
with Aion.Runtime;
with Runtime_Future_Demo_Jobs;

procedure Runtime_Future_Demo is
   package Int_Block_On is new Aion.Block_On.Generic_Block_On
     (Runtime_Future_Demo_Jobs.Int_Futures);

   function Make_Runtime return Aion.Runtime.Runtime_Handle is
      Config : Aion.Config.Runtime_Config := Aion.Config.Default;
   begin
      Config := Aion.Config.With_Name (Config, "runtime-future-demo");
      Config := Aion.Config.With_Workers (Config, 2);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 64);
      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Start_Result : Aion.Runtime.Operation_Results.Result_Type;
   Spawn_Result : Aion.Runtime.Spawn_Results.Result_Type;
   Await_Result : Runtime_Future_Demo_Jobs.Int_Futures.Value_Results.Result_Type;
   Stop_Result  : Aion.Runtime.Operation_Results.Result_Type;
begin
   Runtime_Future_Demo_Jobs.Reset;

   Start_Result := Aion.Runtime.Start (Runtime);

   if Aion.Runtime.Operation_Results.Is_Err (Start_Result) then
      Ada.Text_IO.Put_Line ("runtime failed to start");
      return;
   end if;

   Spawn_Result := Aion.Runtime.Spawn
     (Runtime,
      "complete-demo-future",
      Runtime_Future_Demo_Jobs.Complete_From_Runtime'Access);

   if Aion.Runtime.Spawn_Results.Is_Err (Spawn_Result) then
      Ada.Text_IO.Put_Line ("failed to spawn runtime future job");
      Stop_Result := Aion.Runtime.Shutdown (Runtime);
      return;
   end if;

   Await_Result := Int_Block_On.Run_Timeout
     (Runtime_Future_Demo_Jobs.Future,
      2_000);

   if Runtime_Future_Demo_Jobs.Int_Futures.Value_Results.Is_Ok (Await_Result) then
      Ada.Text_IO.Put_Line
        ("runtime future value =" &
         Integer'Image
           (Runtime_Future_Demo_Jobs.Int_Futures.Value_Results.Value (Await_Result)));
   else
      Ada.Text_IO.Put_Line ("runtime future timed out or failed");
   end if;

   Stop_Result := Aion.Runtime.Shutdown (Runtime);

   if Aion.Runtime.Operation_Results.Is_Err (Stop_Result) then
      Ada.Text_IO.Put_Line ("runtime shutdown failed");
   end if;
end Runtime_Future_Demo;
