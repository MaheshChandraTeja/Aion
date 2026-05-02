with Aion.Clock;
with Aion.Timer_Queue;
with Aion.Types;
with Test_Support;

procedure Test_Timer_Accuracy is
   use type Aion.Types.Milliseconds;
   Service : Aion.Timer_Queue.Timer_Service_Access := Aion.Timer_Queue.Create_Service (32);
   Started : constant Aion.Clock.Instant := Aion.Clock.Now;
   Finished : Aion.Clock.Instant;
   Scheduled : Aion.Timer_Queue.Schedule_Results.Result_Type;
   Timer : Aion.Timer_Queue.Timer_Handle;
   Result : Aion.Timer_Queue.Timer_Futures.Value_Results.Result_Type;
   Elapsed : Aion.Types.Milliseconds;
begin
   Test_Support.Section ("timer accuracy");

   Scheduled := Aion.Timer_Queue.Schedule (Service, 20, "accuracy");
   Test_Support.Assert (Aion.Timer_Queue.Schedule_Results.Is_Ok (Scheduled), "timer scheduled");
   Timer := Aion.Timer_Queue.Schedule_Results.Value (Scheduled);

   Result := Aion.Timer_Queue.Timer_Futures.Await_Timeout
     (Aion.Timer_Queue.Future_Of (Timer), 1_000);
   Finished := Aion.Clock.Now;
   Elapsed := Aion.Clock.Milliseconds_Between (Started, Finished);

   Test_Support.Assert (Aion.Timer_Queue.Timer_Futures.Value_Results.Is_Ok (Result), "timer completed");
   Test_Support.Assert (Elapsed >= 15, "timer did not fire drastically early");
   Test_Support.Assert (Elapsed <= 500, "timer fired within tolerance");

   Aion.Timer_Queue.Destroy (Service);
   Test_Support.Pass ("timer accuracy stayed within practical CI tolerance");
end Test_Timer_Accuracy;
