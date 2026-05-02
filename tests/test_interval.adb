with Aion.Interval;
with Aion.Timer_Queue;
with Test_Support;

procedure Test_Interval is
   Service : Aion.Timer_Queue.Timer_Service_Access := Aion.Timer_Queue.Create_Service (32);
   Created : Aion.Interval.Interval_Results.Result_Type;
   Ticker  : Aion.Interval.Interval;
   Scheduled : Aion.Timer_Queue.Schedule_Results.Result_Type;
   Timer : Aion.Timer_Queue.Timer_Handle;
   Result : Aion.Timer_Queue.Timer_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("interval");

   Created := Aion.Interval.Every (Service, 5, "test-interval");
   Test_Support.Assert (Aion.Interval.Interval_Results.Is_Ok (Created), "interval is created");
   Ticker := Aion.Interval.Interval_Results.Value (Created);

   Scheduled := Aion.Interval.Tick (Ticker);
   Test_Support.Assert (Aion.Timer_Queue.Schedule_Results.Is_Ok (Scheduled), "first tick scheduled");
   Timer := Aion.Timer_Queue.Schedule_Results.Value (Scheduled);
   Result := Aion.Timer_Queue.Timer_Futures.Await_Timeout
     (Aion.Timer_Queue.Future_Of (Timer), 500);
   Test_Support.Assert (Aion.Timer_Queue.Timer_Futures.Value_Results.Is_Ok (Result), "first tick completes");

   Scheduled := Aion.Interval.Tick (Ticker);
   Test_Support.Assert (Aion.Timer_Queue.Schedule_Results.Is_Ok (Scheduled), "second tick scheduled");
   Test_Support.Assert (Aion.Interval.Ticks_Of (Ticker) = 2, "tick count increments");

   Aion.Timer_Queue.Destroy (Service);
   Test_Support.Pass ("interval schedules repeated runtime-owned timers");
end Test_Interval;
