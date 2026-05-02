with Ada.Text_IO;
with Aion.Future;
with Aion.Selector;

procedure Select_Demo is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Select is new Aion.Selector.Generic_Select (Int_Futures);

   F1 : constant Int_Futures.Future_Handle := Int_Futures.Create (Name => "first");
   F2 : constant Int_Futures.Future_Handle := Int_Futures.Create (Name => "second");
   Items : constant Int_Select.Future_Array (1 .. 2) := (F1, F2);
   Ignored : Int_Futures.Operation_Results.Result_Type;
   Choice  : Aion.Selector.Selection_Results.Result_Type;
begin
   Ada.Text_IO.Put_Line ("Aion selector demo");

   Ignored := Int_Futures.Complete_Success (F2, 22);

   if not Int_Futures.Operation_Results.Is_Ok (Ignored) then
      Ada.Text_IO.Put_Line ("failed to complete second future");
      return;
   end if;

   Choice := Int_Select.First_Ready (Items);

   if Aion.Selector.Selection_Results.Is_Ok (Choice) and then
      Aion.Selector.Selection_Results.Value (Choice).Ready
   then
      Ada.Text_IO.Put_Line
        ("ready future index=" & Natural'Image (Aion.Selector.Selection_Results.Value (Choice).Index));
   else
      Ada.Text_IO.Put_Line ("no future became ready");
   end if;
end Select_Demo;
