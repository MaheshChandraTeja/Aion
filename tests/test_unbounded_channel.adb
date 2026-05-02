with Aion.Channel.Unbounded;
with Aion.Sync;
with Test_Support;

procedure Test_Unbounded_Channel is
   package Int_Channel is new Aion.Channel.Unbounded.Generic_Unbounded_Channel (Integer);
   C  : Int_Channel.Unbounded_Channel (High_Watermark => 32, Max_Waiters => 8);
   R  : Int_Channel.Message_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Channel.Unbounded");

   for I in 1 .. 10 loop
      declare
         Ignored : constant Aion.Sync.Boolean_Results.Result_Type := Int_Channel.Try_Send (C, I);
         pragma Unreferenced (Ignored);
      begin
         null;
      end;
   end loop;

   Test_Support.Assert (Int_Channel.Buffered_Count_Of (C) = 10, "unbounded facade should hold queued items");
   R := Int_Channel.Try_Receive (C);
   Test_Support.Assert (Int_Channel.Message_Results.Is_Ok (R), "unbounded receive should complete");
   Test_Support.Assert (Int_Channel.Message_Results.Value (R) = 1, "unbounded channel should preserve FIFO order");

   Test_Support.Pass ("unbounded channel FIFO works");
end Test_Unbounded_Channel;
