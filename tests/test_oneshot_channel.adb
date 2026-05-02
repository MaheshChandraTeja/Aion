with Aion.Channel.Oneshot;
with Aion.Sync;
with Test_Support;

procedure Test_Oneshot_Channel is
   package Int_Oneshot is new Aion.Channel.Oneshot.Generic_Oneshot_Channel (Integer);
   C  : Int_Oneshot.Oneshot_Channel;
   RF : Int_Oneshot.Message_Futures.Future_Handle;
   SF : Aion.Sync.Boolean_Futures.Future_Handle;
   RR : Int_Oneshot.Message_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Channel.Oneshot");

   RF := Int_Oneshot.Receive (C);
   Test_Support.Assert (Int_Oneshot.Message_Futures.Is_Pending (RF), "oneshot receive should wait before send");

   SF := Int_Oneshot.Send (C, 99);
   Test_Support.Assert (Aion.Sync.Boolean_Futures.Is_Ready (SF), "oneshot send should complete receiver");

   RR := Int_Oneshot.Message_Futures.Await (RF);
   Test_Support.Assert (Int_Oneshot.Message_Futures.Value_Results.Is_Ok (RR), "oneshot receiver should complete");
   Test_Support.Assert (Int_Oneshot.Message_Futures.Value_Results.Value (RR) = 99, "oneshot value should match");

   Test_Support.Pass ("oneshot handoff works");
end Test_Oneshot_Channel;
