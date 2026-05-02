with Aion.Channel.Bounded;
with Aion.Sync;
with Test_Support;

procedure Test_Channel_Backpressure is
   package Int_Channel is new Aion.Channel.Bounded.Generic_Bounded_Channel (Integer);
   C : Int_Channel.Bounded_Channel (Capacity => 1, Max_Waiters => 4);
   S1, S2 : Aion.Sync.Boolean_Futures.Future_Handle;
   R : Int_Channel.Message_Futures.Future_Handle;
begin
   Test_Support.Section ("Aion.Channel backpressure");

   S1 := Int_Channel.Send (C, 1);
   S2 := Int_Channel.Send (C, 2);
   Test_Support.Assert (Aion.Sync.Boolean_Futures.Is_Ready (S1), "first send should fit immediately");
   Test_Support.Assert (Aion.Sync.Boolean_Futures.Is_Pending (S2), "second send should wait because capacity is full");

   R := Int_Channel.Receive (C);
   Test_Support.Assert (Int_Channel.Message_Futures.Is_Ready (R), "receive should complete from buffer");
   Test_Support.Assert (Aion.Sync.Boolean_Futures.Is_Ready (S2), "waiting sender should complete after capacity opens");

   Test_Support.Pass ("bounded channel backpressure works");
end Test_Channel_Backpressure;
