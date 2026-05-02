with Aion.Net;
with Aion.Net.Address;
with Aion.Net.UDP;
with Test_Support;

procedure Test_UDP_Socket is
   Datagram : constant Aion.Net.UDP.Datagram :=
     (Payload => Aion.Net.From_String ("ping"),
      Peer    => Aion.Net.Address.Localhost (7777));
begin
   Test_Support.Section ("udp socket model");
   Test_Support.Assert (not Aion.Net.UDP.Is_Open (Aion.Net.UDP.Null_Socket), "null UDP socket should be closed");
   Test_Support.Assert (Aion.Net.To_String (Datagram.Payload) = "ping", "UDP datagram payload should round-trip");
   Test_Support.Pass (Aion.Net.UDP.Image (Datagram));
end Test_UDP_Socket;
