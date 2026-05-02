with Aion.Errors;
with Aion.Timer_Queue;
with Test_Support;

procedure Test_Timer_Cancel is
   use type Aion.Errors.Error_Code;
   Service : Aion.Timer_Queue.Timer_Service_Access := Aion.Timer_Queue.Create_Service (16);
   Scheduled : Aion.Timer_Queue.Schedule_Results.Result_Type;
   Timer : Aion.Timer_Queue.Timer_Handle;
   Cancelled : Aion.Timer_Queue.Operation_Results.Result_Type;
   Result : Aion.Timer_Queue.Timer_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("timer cancellation");

   Scheduled := Aion.Timer_Queue.Schedule (Service, 500, "cancel-me");
   Test_Support.Assert (Aion.Timer_Queue.Schedule_Results.Is_Ok (Scheduled), "timer scheduled");
   Timer := Aion.Timer_Queue.Schedule_Results.Value (Scheduled);

   Cancelled := Aion.Timer_Queue.Cancel (Timer);
   Test_Support.Assert (Aion.Timer_Queue.Operation_Results.Is_Ok (Cancelled), "timer cancelled");

   Result := Aion.Timer_Queue.Timer_Futures.Await_Timeout
     (Aion.Timer_Queue.Future_Of (Timer), 100);
   Test_Support.Assert (Aion.Timer_Queue.Timer_Futures.Value_Results.Is_Err (Result), "cancelled timer future fails");
   Test_Support.Assert
     (Aion.Errors.Code_Of (Aion.Timer_Queue.Timer_Futures.Value_Results.Error (Result)) = Aion.Errors.Cancelled,
      "cancelled timer reports Cancelled");

   Aion.Timer_Queue.Destroy (Service);
   Test_Support.Pass ("timer cancellation completes future safely");
end Test_Timer_Cancel;
