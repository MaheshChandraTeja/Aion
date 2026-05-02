with Aion.Future;
with Aion.Promise;
with Test_Support;

procedure Test_Future_Stress is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);

   Count : constant Positive := 1_000;

   type Future_Array is array (Positive range <>) of Int_Futures.Future_Handle;
   type Promise_Array is array (Positive range <>) of Int_Promises.Promise_Handle;

   Futures  : Future_Array (1 .. Count);
   Promises : Promise_Array (1 .. Count);
   Complete_Result : Int_Promises.Operation_Results.Result_Type;
   Await_Result    : Int_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("future stress");

   for I in 1 .. Count loop
      Int_Promises.New_Promise
        (Promises (I),
         Futures (I),
         "stress-future");
   end loop;

   for I in 1 .. Count loop
      Complete_Result := Int_Promises.Complete (Promises (I), I);
      Test_Support.Assert
        (Int_Promises.Operation_Results.Is_Ok (Complete_Result),
         "stress promise completion succeeds");
   end loop;

   for I in 1 .. Count loop
      Await_Result := Int_Futures.Await (Futures (I));
      Test_Support.Assert
        (Int_Futures.Value_Results.Is_Ok (Await_Result),
         "stress future await succeeds");
      Test_Support.Assert
        (Int_Futures.Value_Results.Value (Await_Result) = I,
         "stress future preserves value ordering");
   end loop;

   Test_Support.Pass ("1,000 future/promise pairs complete and await cleanly");
end Test_Future_Stress;
