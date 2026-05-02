with Aion.Net;
with Test_Support;

procedure Test_TCP_Echo is
   Payload : constant Aion.Net.Net_Buffer := Aion.Net.From_String ("aion-echo");
begin
   Test_Support.Section ("tcp echo payload model");
   Test_Support.Assert (Aion.Net.Length_Of (Payload) = 9, "payload length should match");
   Test_Support.Assert (Aion.Net.To_String (Payload) = "aion-echo", "payload should round-trip");
   Test_Support.Pass (Aion.Net.Image (Payload));
end Test_TCP_Echo;
