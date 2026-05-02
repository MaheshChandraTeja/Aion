with Ada.Text_IO;
with Aion.Errors;
with Aion.Future;
with Aion.Promise;
with Aion.Timeout;

procedure Timeout_Demo is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);
   package Int_Timeouts is new Aion.Timeout.Generic_Timeout (Int_Futures);

   Promise : Int_Promises.Promise_Handle;
   Future  : Int_Futures.Future_Handle;
   Result  : Int_Futures.Value_Results.Result_Type;
begin
   Ada.Text_IO.Put_Line ("Aion timeout demo");

   Int_Promises.New_Promise (Promise, Future, "demo-timeout");
   Result := Int_Timeouts.Await_Within (Future, 50);

   if Int_Futures.Value_Results.Is_Err (Result) then
      Ada.Text_IO.Put_Line
        ("timed out with: " &
         Aion.Errors.Image (Int_Futures.Value_Results.Error (Result)));
   end if;
end Timeout_Demo;
