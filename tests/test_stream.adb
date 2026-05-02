with Aion.Stream;
with Aion.Sync;
with Test_Support;

procedure Test_Stream is
   package Int_Stream is new Aion.Stream.Generic_Stream (Integer);
   S : Int_Stream.Async_Stream (High_Watermark => 16, Max_Waiters => 4);
   F : Int_Stream.Item_Futures.Future_Handle;
   R : Int_Stream.Item_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Stream");

   declare
      Ignored : constant Aion.Sync.Boolean_Futures.Future_Handle := Int_Stream.Push (S, 123);
      pragma Unreferenced (Ignored);
   begin
      null;
   end;

   F := Int_Stream.Next (S);
   R := Int_Stream.Item_Futures.Await (F);
   Test_Support.Assert (Int_Stream.Item_Futures.Value_Results.Value (R) = 123, "stream next should return pushed item");

   Test_Support.Pass ("stream push/next works");
end Test_Stream;
