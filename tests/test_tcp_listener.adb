with Aion.Net.Address;
with Test_Support;

procedure Test_TCP_Listener is
   Address : constant Aion.Net.Address.Network_Address := Aion.Net.Address.Localhost (8080);
begin
   Test_Support.Section ("tcp listener address model");
   Test_Support.Assert (Aion.Net.Address.Is_Valid (Address), "localhost:8080 should be valid");
   Test_Support.Assert
     (Aion.Net.Address.Port_Of (Address) = 8080,
      "listener address should preserve port");
   Test_Support.Pass (Aion.Net.Address.Image (Address));
end Test_TCP_Listener;
