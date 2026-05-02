with Ada.Text_IO;
with Aion.Block_On;
with Aion.Future;
with Aion.Promise;

procedure Future_Promise_Demo is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);
   package Int_Block_On is new Aion.Block_On.Generic_Block_On (Int_Futures);

   Promise : Int_Promises.Promise_Handle;
   Future  : Int_Futures.Future_Handle;
   Complete_Result : Int_Promises.Operation_Results.Result_Type;
   Await_Result    : Int_Futures.Value_Results.Result_Type;
begin
   Int_Promises.New_Promise (Promise, Future, "demo-future");

   Complete_Result := Int_Promises.Complete (Promise, 2026);

   if Int_Promises.Operation_Results.Is_Err (Complete_Result) then
      Ada.Text_IO.Put_Line ("complete failed");
      return;
   end if;

   Await_Result := Int_Block_On.Run (Future);

   if Int_Futures.Value_Results.Is_Ok (Await_Result) then
      Ada.Text_IO.Put_Line
        ("future value =" & Integer'Image (Int_Futures.Value_Results.Value (Await_Result)));
   else
      Ada.Text_IO.Put_Line ("future failed");
   end if;
end Future_Promise_Demo;
