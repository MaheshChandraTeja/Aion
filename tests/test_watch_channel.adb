with Aion.Channel.Watch;
with Test_Support;

procedure Test_Watch_Channel is
   package Int_Watch is new Aion.Channel.Watch.Generic_Watch_Channel (Integer);
   C  : Int_Watch.Watch_Channel (Max_Subscribers => 4);
   S  : Aion.Channel.Watch.Subscriber_Results.Result_Type;
   Id : Aion.Channel.Watch.Subscriber_Id;
   F  : Int_Watch.Message_Futures.Future_Handle;
   R  : Int_Watch.Message_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Channel.Watch");

   Int_Watch.Initialize (C, 10);
   S := Int_Watch.Subscribe (C);
   Test_Support.Assert (Aion.Channel.Watch.Subscriber_Results.Is_Ok (S), "watch subscriber should be accepted");
   Id := Aion.Channel.Watch.Subscriber_Results.Value (S);

   F := Int_Watch.Receive_Changed (C, Id);
   R := Int_Watch.Message_Futures.Await (F);
   Test_Support.Assert (Int_Watch.Message_Futures.Value_Results.Value (R) = 10, "watch subscriber should see initial value");

   Test_Support.Pass ("watch channel latest-value delivery works");
end Test_Watch_Channel;
