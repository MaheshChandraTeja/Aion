with Aion.Future;
with Aion.Promise;
with Test_Support;

procedure Test_Promise_Completion is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);

   P : Int_Promises.Promise_Handle;
   F : Int_Futures.Future_Handle;
   Complete_Result : Int_Promises.Operation_Results.Result_Type;
   Await_Result    : Int_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("promise completion");

   Int_Promises.New_Promise (P, F, "promise-completion");
   Test_Support.Assert (Int_Promises.Is_Valid (P), "promise is valid");
   Test_Support.Assert (Int_Futures.Is_Valid (F), "future side is valid");

   Complete_Result := Int_Promises.Complete (P, 123);
   Test_Support.Assert
     (Int_Promises.Operation_Results.Is_Ok (Complete_Result),
      "promise completes successfully");

   Await_Result := Int_Futures.Await (F);
   Test_Support.Assert
     (Int_Futures.Value_Results.Is_Ok (Await_Result),
      "await returns success");
   Test_Support.Assert
     (Int_Futures.Value_Results.Value (Await_Result) = 123,
      "await returns promised value");

   Complete_Result := Int_Promises.Complete (P, 999);
   Test_Support.Assert
     (Int_Promises.Operation_Results.Is_Err (Complete_Result),
      "second completion is rejected");

   Test_Support.Pass ("promise one-shot success completion works");
end Test_Promise_Completion;
