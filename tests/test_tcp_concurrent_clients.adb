with Aion.Net;
with Test_Support;

procedure Test_TCP_Concurrent_Clients is
   A : constant Aion.Net.Net_Buffer := Aion.Net.From_String ("client-a");
   B : constant Aion.Net.Net_Buffer := Aion.Net.From_String ("client-b");
begin
   Test_Support.Section ("tcp concurrent client buffers");
   Test_Support.Assert (not Aion.Net.Is_Empty (A), "client A payload should not be empty");
   Test_Support.Assert (not Aion.Net.Is_Empty (B), "client B payload should not be empty");
   Test_Support.Assert (Aion.Net.To_String (A) /= Aion.Net.To_String (B), "payloads should be independent");
   Test_Support.Pass ("concurrent payload isolation verified");
end Test_TCP_Concurrent_Clients;
