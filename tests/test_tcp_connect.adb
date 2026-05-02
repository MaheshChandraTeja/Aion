with Aion.Net.Address;
with Aion.Net.TCP_Stream;
with Test_Support;

procedure Test_TCP_Connect is
   Address : constant Aion.Net.Address.Network_Address := Aion.Net.Address.From ("127.0.0.1", 9001);
begin
   Test_Support.Section ("tcp connect API shape");
   Test_Support.Assert (Aion.Net.Address.Is_Localhost (Address), "connect target should be localhost");
   Test_Support.Assert
     (not Aion.Net.TCP_Stream.Is_Open (Aion.Net.TCP_Stream.Null_Stream),
      "null tcp stream must be closed");
   Test_Support.Pass ("TCP connect future API available");
end Test_TCP_Connect;
