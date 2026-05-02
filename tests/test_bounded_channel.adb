with Aion.Channel.Bounded;
with Aion.Sync;
with Test_Support;

procedure Test_Bounded_Channel is
   package Int_Channel is new Aion.Channel.Bounded.Generic_Bounded_Channel (Integer);
   C  : Int_Channel.Bounded_Channel (Capacity => 2, Max_Waiters => 8);
   SF : Aion.Sync.Boolean_Futures.Future_Handle;
   RF : Int_Channel.Message_Futures.Future_Handle;
   SR : Aion.Sync.Boolean_Futures.Value_Results.Result_Type;
   RR : Int_Channel.Message_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Channel.Bounded");

   SF := Int_Channel.Send (C, 42);
   SR := Aion.Sync.Boolean_Futures.Await (SF);
   Test_Support.Assert (Aion.Sync.Boolean_Futures.Value_Results.Is_Ok (SR), "bounded send should complete");
   Test_Support.Assert (Int_Channel.Buffered_Count_Of (C) = 1, "bounded channel should buffer one item");

   RF := Int_Channel.Receive (C);
   RR := Int_Channel.Message_Futures.Await (RF);
   Test_Support.Assert (Int_Channel.Message_Futures.Value_Results.Is_Ok (RR), "bounded receive should complete");
   Test_Support.Assert (Int_Channel.Message_Futures.Value_Results.Value (RR) = 42, "bounded receive should return sent value");

   Test_Support.Pass ("bounded channel send/receive works");
end Test_Bounded_Channel;
