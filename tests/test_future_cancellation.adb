with Aion.Completion;
with Aion.Errors;
with Aion.Future;
with Aion.Promise;
with Test_Support;

procedure Test_Future_Cancellation is
   use type Aion.Completion.Completion_State;
   use type Aion.Errors.Error_Code;

   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);

   P : Int_Promises.Promise_Handle;
   F : Int_Futures.Future_Handle;
   Cancel_Result : Int_Promises.Operation_Results.Result_Type;
   Await_Result  : Int_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("future cancellation");

   Int_Promises.New_Promise (P, F, "future-cancellation");
   Cancel_Result := Int_Promises.Cancel (P, "test cancellation");

   Test_Support.Assert
     (Int_Promises.Operation_Results.Is_Ok (Cancel_Result),
      "promise cancellation succeeds");
   Test_Support.Assert
     (Int_Futures.State_Of (F) = Aion.Completion.Completion_Cancelled,
      "future state is cancelled");

   Await_Result := Int_Futures.Await (F);
   Test_Support.Assert
     (Int_Futures.Value_Results.Is_Err (Await_Result),
      "await observes cancellation");
   Test_Support.Assert
     (Aion.Errors.Code_Of (Int_Futures.Value_Results.Error (Await_Result)) =
      Aion.Errors.Cancelled,
      "cancelled error code propagates");

   Test_Support.Pass ("future cancellation propagation works");
end Test_Future_Cancellation;
