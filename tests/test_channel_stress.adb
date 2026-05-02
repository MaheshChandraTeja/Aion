with Aion.Channel.Bounded;
with Aion.Sync;
with Test_Support;

procedure Test_Channel_Stress is
   package Int_Channel is new Aion.Channel.Bounded.Generic_Bounded_Channel (Integer);
   C : Int_Channel.Bounded_Channel (Capacity => 128, Max_Waiters => 128);
   Sum : Integer := 0;
begin
   Test_Support.Section ("Aion.Channel stress");

   for I in 1 .. 100 loop
      declare
         F : constant Aion.Sync.Boolean_Futures.Future_Handle := Int_Channel.Send (C, I);
         pragma Unreferenced (F);
      begin
         null;
      end;
   end loop;

   for I in 1 .. 100 loop
      declare
         F : constant Int_Channel.Message_Futures.Future_Handle := Int_Channel.Receive (C);
         R : constant Int_Channel.Message_Futures.Value_Results.Result_Type := Int_Channel.Message_Futures.Await (F);
      begin
         Sum := Sum + Int_Channel.Message_Futures.Value_Results.Value (R);
      end;
   end loop;

   Test_Support.Assert (Sum = 5_050, "channel stress FIFO sum should match");
   Test_Support.Pass ("channel stress run completed");
end Test_Channel_Stress;
