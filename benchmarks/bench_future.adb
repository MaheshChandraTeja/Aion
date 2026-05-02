with Ada.Calendar;
with Ada.Text_IO;
with Aion.Future;
with Aion.Promise;

procedure Bench_Future is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);

   Count : constant Positive := 10_000;

   type Future_Array is array (Positive range <>) of Int_Futures.Future_Handle;
   type Promise_Array is array (Positive range <>) of Int_Promises.Promise_Handle;

   Futures  : Future_Array (1 .. Count);
   Promises : Promise_Array (1 .. Count);
   Start_Time : Ada.Calendar.Time;
   End_Time   : Ada.Calendar.Time;
   Result : Int_Promises.Operation_Results.Result_Type;
   Awaited : Int_Futures.Value_Results.Result_Type;
begin
   Start_Time := Ada.Calendar.Clock;

   for I in 1 .. Count loop
      Int_Promises.New_Promise (Promises (I), Futures (I), "bench-future");
   end loop;

   for I in 1 .. Count loop
      Result := Int_Promises.Complete (Promises (I), I);

      if Int_Promises.Operation_Results.Is_Err (Result) then
         raise Program_Error with "promise completion failed during benchmark";
      end if;
   end loop;

   for I in 1 .. Count loop
      Awaited := Int_Futures.Await (Futures (I));

      if Int_Futures.Value_Results.Is_Err (Awaited) then
         raise Program_Error with "future await failed during benchmark";
      end if;
   end loop;

   End_Time := Ada.Calendar.Clock;

   Ada.Text_IO.Put_Line
     ("future create/complete/await count=" & Positive'Image (Count) &
      " seconds=" & Duration'Image (End_Time - Start_Time));
end Bench_Future;
