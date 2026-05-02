with Aion.Channel.Broadcast;
with Aion.Sync;
with Test_Support;

procedure Test_Broadcast_Channel is
   package Int_Broadcast is new Aion.Channel.Broadcast.Generic_Broadcast_Channel (Integer);
   C  : Int_Broadcast.Broadcast_Channel (Max_Subscribers => 4, Per_Subscriber_Capacity => 8);
   S1 : Aion.Channel.Broadcast.Subscriber_Results.Result_Type;
   S2 : Aion.Channel.Broadcast.Subscriber_Results.Result_Type;
   Id1, Id2 : Aion.Channel.Broadcast.Subscriber_Id;
   R1, R2 : Int_Broadcast.Message_Futures.Future_Handle;
   V1, V2 : Int_Broadcast.Message_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Channel.Broadcast");

   S1 := Int_Broadcast.Subscribe (C);
   S2 := Int_Broadcast.Subscribe (C);
   Test_Support.Assert (Aion.Channel.Broadcast.Subscriber_Results.Is_Ok (S1), "first subscriber should be accepted");
   Test_Support.Assert (Aion.Channel.Broadcast.Subscriber_Results.Is_Ok (S2), "second subscriber should be accepted");
   Id1 := Aion.Channel.Broadcast.Subscriber_Results.Value (S1);
   Id2 := Aion.Channel.Broadcast.Subscriber_Results.Value (S2);

   R1 := Int_Broadcast.Receive (C, Id1);
   R2 := Int_Broadcast.Receive (C, Id2);
   declare
      Ignored : constant Aion.Sync.Boolean_Futures.Future_Handle := Int_Broadcast.Publish (C, 7);
      pragma Unreferenced (Ignored);
   begin
      null;
   end;

   V1 := Int_Broadcast.Message_Futures.Await (R1);
   V2 := Int_Broadcast.Message_Futures.Await (R2);
   Test_Support.Assert (Int_Broadcast.Message_Futures.Value_Results.Value (V1) = 7, "subscriber one should receive broadcast");
   Test_Support.Assert (Int_Broadcast.Message_Futures.Value_Results.Value (V2) = 7, "subscriber two should receive broadcast");

   Test_Support.Pass ("broadcast channel fanout works");
end Test_Broadcast_Channel;
