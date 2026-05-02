with Ada.Text_IO;
with Aion.Runtime;
with Aion.Sleep;
with Aion.Timer_Queue;

procedure Timer_Demo is
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Started : Aion.Runtime.Operation_Results.Result_Type;
   Stopped : Aion.Runtime.Operation_Results.Result_Type;
   Scheduled : Aion.Timer_Queue.Schedule_Results.Result_Type;
   Timer : Aion.Timer_Queue.Timer_Handle;
   Done : Aion.Timer_Queue.Timer_Futures.Value_Results.Result_Type;
begin
   Ada.Text_IO.Put_Line ("Aion timer demo");
   Started := Aion.Runtime.Start (Runtime);

   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line ("runtime failed to start");
      return;
   end if;

   Scheduled := Aion.Sleep.Sleep_For (Runtime, 250, "demo-sleep");

   if Aion.Timer_Queue.Schedule_Results.Is_Ok (Scheduled) then
      Timer := Aion.Timer_Queue.Schedule_Results.Value (Scheduled);
      Ada.Text_IO.Put_Line ("scheduled: " & Aion.Timer_Queue.Image (Timer));
      Done := Aion.Timer_Queue.Timer_Futures.Await (Aion.Timer_Queue.Future_Of (Timer));

      if Aion.Timer_Queue.Timer_Futures.Value_Results.Is_Ok (Done) then
         Ada.Text_IO.Put_Line ("timer completed");
      end if;
   end if;

   Stopped := Aion.Runtime.Shutdown (Runtime);
   pragma Unreferenced (Stopped);
end Timer_Demo;
