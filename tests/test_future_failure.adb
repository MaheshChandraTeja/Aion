with Aion.Errors;
with Aion.Future;
with Aion.Promise;
with Test_Support;

procedure Test_Future_Failure is
   use type Aion.Errors.Error_Code;

   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);

   P : Int_Promises.Promise_Handle;
   F : Int_Futures.Future_Handle;
   Fail_Result  : Int_Promises.Operation_Results.Result_Type;
   Await_Result : Int_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("future failure");

   Int_Promises.New_Promise (P, F, "future-failure");
   Fail_Result := Int_Promises.Fail
     (P,
      Aion.Errors.Runtime_Error,
      "intentional failure",
      "Test_Future_Failure");

   Test_Support.Assert
     (Int_Promises.Operation_Results.Is_Ok (Fail_Result),
      "promise failure completes future");

   Await_Result := Int_Futures.Await (F);
   Test_Support.Assert
     (Int_Futures.Value_Results.Is_Err (Await_Result),
      "await observes failure");
   Test_Support.Assert
     (Aion.Errors.Code_Of (Int_Futures.Value_Results.Error (Await_Result)) =
      Aion.Errors.Runtime_Error,
      "failure error code propagates");

   Test_Support.Pass ("future failure propagation works");
end Test_Future_Failure;
