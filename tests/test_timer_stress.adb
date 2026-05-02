with Aion.Timer_Queue;
with Test_Support;

procedure Test_Timer_Stress is
   Count : constant Positive := 1_000;
   Service : Aion.Timer_Queue.Timer_Service_Access := Aion.Timer_Queue.Create_Service (Count + 16);
   Timers : array (1 .. Count) of Aion.Timer_Queue.Timer_Handle;
   Scheduled : Aion.Timer_Queue.Schedule_Results.Result_Type;
   Result : Aion.Timer_Queue.Timer_Futures.Value_Results.Result_Type;
   Stats : Aion.Timer_Queue.Timer_Stats;
begin
   Test_Support.Section ("timer stress");

   for Index in Timers'Range loop
      Scheduled := Aion.Timer_Queue.Schedule (Service, 1, "stress-timer");
      Test_Support.Assert (Aion.Timer_Queue.Schedule_Results.Is_Ok (Scheduled), "stress timer schedules");
      Timers (Index) := Aion.Timer_Queue.Schedule_Results.Value (Scheduled);
   end loop;

   for Index in Timers'Range loop
      Result := Aion.Timer_Queue.Timer_Futures.Await_Timeout
        (Aion.Timer_Queue.Future_Of (Timers (Index)), 2_000);
      Test_Support.Assert (Aion.Timer_Queue.Timer_Futures.Value_Results.Is_Ok (Result), "stress timer completes");
   end loop;

   Stats := Aion.Timer_Queue.Stats_Of (Service.all);
   Test_Support.Assert (Stats.Fired_Total >= Count, "all stress timers fired");
   Test_Support.Assert (Stats.Pending = 0, "timer queue drained");

   Aion.Timer_Queue.Destroy (Service);
   Test_Support.Pass ("timer heap handled 1000 timers");
end Test_Timer_Stress;
