with Aion.Awaitable;
with Aion.Future;
with Aion.Promise;
with Test_Support;

procedure Test_Awaitable is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);
   package Int_Awaitables is new Aion.Awaitable.Generic_Awaitable (Int_Futures);

   P : Int_Promises.Promise_Handle;
   F : Int_Futures.Future_Handle;
   A : Int_Awaitables.Awaitable_Handle;
   Complete_Result : Int_Promises.Operation_Results.Result_Type;
   Await_Result    : Int_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("awaitable");

   Int_Promises.New_Promise (P, F, "awaitable-future");
   A := Int_Awaitables.From_Future (F, "awaitable-wrapper");

   Test_Support.Assert (Int_Awaitables.Is_Valid (A), "awaitable is valid");
   Test_Support.Assert (not Int_Awaitables.Is_Done (A), "awaitable starts incomplete");

   Complete_Result := Int_Promises.Complete (P, 77);
   Test_Support.Assert
     (Int_Promises.Operation_Results.Is_Ok (Complete_Result),
      "promise completes awaitable future");

   Await_Result := Int_Awaitables.Await (A);
   Test_Support.Assert
     (Int_Futures.Value_Results.Is_Ok (Await_Result),
      "awaitable returns success");
   Test_Support.Assert
     (Int_Futures.Value_Results.Value (Await_Result) = 77,
      "awaitable returns value");

   Test_Support.Pass ("awaitable facade works");
end Test_Awaitable;
