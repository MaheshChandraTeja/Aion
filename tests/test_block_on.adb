with Aion.Block_On;
with Aion.Future;
with Aion.Promise;
with Test_Support;

procedure Test_Block_On is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);
   package Int_Block_On is new Aion.Block_On.Generic_Block_On (Int_Futures);

   P : Int_Promises.Promise_Handle;
   F : Int_Futures.Future_Handle;
   Complete_Result : Int_Promises.Operation_Results.Result_Type;
   Block_Result    : Int_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("block on");

   Int_Promises.New_Promise (P, F, "block-on");
   Complete_Result := Int_Promises.Complete (P, 314);
   Test_Support.Assert
     (Int_Promises.Operation_Results.Is_Ok (Complete_Result),
      "promise completes before block_on");

   Block_Result := Int_Block_On.Run (F);
   Test_Support.Assert
     (Int_Futures.Value_Results.Is_Ok (Block_Result),
      "block_on returns success");
   Test_Support.Assert
     (Int_Futures.Value_Results.Value (Block_Result) = 314,
      "block_on returns value");

   Test_Support.Pass ("blocking bridge works");
end Test_Block_On;
