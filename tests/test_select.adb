with Aion.Future;
with Aion.Selection;
with Test_Support;

procedure Test_Select is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Select is new Aion.Selection.Generic_Select (Int_Futures);

   F1 : constant Int_Futures.Future_Handle := Int_Futures.Create (Name => "select.one");
   F2 : constant Int_Futures.Future_Handle := Int_Futures.Create (Name => "select.two");
   Items : constant Int_Select.Future_Array (1 .. 2) := (F1, F2);
   Ignored : Int_Futures.Operation_Results.Result_Type;
   Choice : Aion.Selection.Selection_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Select");

   Ignored := Int_Futures.Complete_Success (F2, 2);
   Choice := Int_Select.First_Ready (Items);
   Test_Support.Assert (Aion.Selection.Selection_Results.Is_Ok (Choice), "select should return a successful selection result");
   Test_Support.Assert (Aion.Selection.Selection_Results.Value (Choice).Ready, "select should find a ready future");
   Test_Support.Assert (Aion.Selection.Selection_Results.Value (Choice).Index = 2, "select should pick the ready future index");

   Test_Support.Pass ("select first-ready works");
end Test_Select;
