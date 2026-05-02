with Ada.Text_IO;
with Aion.Interval;
with Aion.Runtime;
with Aion.Timer_Queue;

procedure Interval_Demo is
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Started : Aion.Runtime.Operation_Results.Result_Type;
   Created : Aion.Interval.Interval_Results.Result_Type;
   Ticker  : Aion.Interval.Interval;
   Scheduled : Aion.Timer_Queue.Schedule_Results.Result_Type;
   Timer : Aion.Timer_Queue.Timer_Handle;
   Done : Aion.Timer_Queue.Timer_Futures.Value_Results.Result_Type;
begin
   Ada.Text_IO.Put_Line ("Aion interval demo");
   Started := Aion.Runtime.Start (Runtime);

   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line ("runtime failed to start");
      return;
   end if;

   Created := Aion.Interval.Every (Aion.Runtime.Timers_Of (Runtime), 100, "heartbeat");

   if Aion.Interval.Interval_Results.Is_Ok (Created) then
      Ticker := Aion.Interval.Interval_Results.Value (Created);

      for Index in 1 .. 3 loop
         Scheduled := Aion.Interval.Tick (Ticker);

         if Aion.Timer_Queue.Schedule_Results.Is_Err (Scheduled) then
            Ada.Text_IO.Put_Line ("tick schedule failed");
            exit;
         end if;

         Timer := Aion.Timer_Queue.Schedule_Results.Value (Scheduled);
         Done := Aion.Timer_Queue.Timer_Futures.Await (Aion.Timer_Queue.Future_Of (Timer));

         if Aion.Timer_Queue.Timer_Futures.Value_Results.Is_Ok (Done) then
            Ada.Text_IO.Put_Line ("tick" & Integer'Image (Index));
         else
            Ada.Text_IO.Put_Line ("tick wait failed");
            exit;
         end if;
      end loop;
   end if;

   declare
      Stopped : Aion.Runtime.Operation_Results.Result_Type := Aion.Runtime.Shutdown (Runtime);
      pragma Unreferenced (Stopped);
   begin
      null;
   end;
end Interval_Demo;
