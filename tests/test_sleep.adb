with Aion.Runtime;
with Aion.Sleep;
with Aion.Timer_Queue;
with Test_Support;

procedure Test_Sleep is
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Started : Aion.Runtime.Operation_Results.Result_Type;
   Stopped : Aion.Runtime.Operation_Results.Result_Type;
   Scheduled : Aion.Timer_Queue.Schedule_Results.Result_Type;
   Timer : Aion.Timer_Queue.Timer_Handle;
   Result : Aion.Timer_Queue.Timer_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("sleep");

   Started := Aion.Runtime.Start (Runtime);
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (Started), "runtime starts");

   Scheduled := Aion.Sleep.Sleep_For (Runtime, 10, "test-sleep");
   Test_Support.Assert (Aion.Timer_Queue.Schedule_Results.Is_Ok (Scheduled), "sleep schedules timer");

   Timer := Aion.Timer_Queue.Schedule_Results.Value (Scheduled);
   Result := Aion.Timer_Queue.Timer_Futures.Await_Timeout
     (Aion.Timer_Queue.Future_Of (Timer), 500);

   Test_Support.Assert (Aion.Timer_Queue.Timer_Futures.Value_Results.Is_Ok (Result), "sleep future completes");
   Test_Support.Assert (Aion.Timer_Queue.Timer_Futures.Value_Results.Value (Result), "sleep returns true");

   Stopped := Aion.Runtime.Shutdown (Runtime);
   Test_Support.Assert (Aion.Runtime.Operation_Results.Is_Ok (Stopped), "runtime shuts down");
   Test_Support.Pass ("sleep future completed without blocking scheduler ownership");
end Test_Sleep;
