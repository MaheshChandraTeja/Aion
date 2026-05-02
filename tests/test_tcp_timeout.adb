with Aion.Time;
with Aion.Types;
with Test_Support;

procedure Test_TCP_Timeout is
   use type Aion.Types.Milliseconds;
   Timeout_Ms : constant := 250;
begin
   Test_Support.Section ("tcp timeout configuration");
   Test_Support.Assert (Aion.Time.Ms (Timeout_Ms) = 250, "timeout helper should preserve ms");
   Test_Support.Pass ("TCP timeout parameter path is available");
end Test_TCP_Timeout;
