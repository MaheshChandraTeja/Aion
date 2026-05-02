with Aion.Errors;
with Aion.Future;
with Aion.Promise;
with Aion.Timeout;
with Test_Support;

procedure Test_Timeout is
   use type Aion.Errors.Error_Code;
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);
   package Int_Timeouts is new Aion.Timeout.Generic_Timeout (Int_Futures);

   Promise : Int_Promises.Promise_Handle;
   Future  : Int_Futures.Future_Handle;
   Result  : Int_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("timeout");

   Int_Promises.New_Promise (Promise, Future, "timeout-test");
   Result := Int_Timeouts.Await_Within (Future, 5);

   Test_Support.Assert (Int_Futures.Value_Results.Is_Err (Result), "pending future times out");
   Test_Support.Assert
     (Aion.Errors.Code_Of (Int_Futures.Value_Results.Error (Result)) = Aion.Errors.Timeout,
      "timeout error code is preserved");

   Test_Support.Pass ("timeout wrapper returns structured timeout error");
end Test_Timeout;
