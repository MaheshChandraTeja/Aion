with Aion.Net.TCP_Listener;
with Aion.Net.TCP_Stream;
with Test_Support;

procedure Test_TCP_Shutdown is
begin
   Test_Support.Section ("tcp close defaults");
   Test_Support.Assert
     (not Aion.Net.TCP_Listener.Is_Open (Aion.Net.TCP_Listener.Null_Listener),
      "null listener should be closed");
   Test_Support.Assert
     (not Aion.Net.TCP_Stream.Is_Open (Aion.Net.TCP_Stream.Null_Stream),
      "null stream should be closed");
   Test_Support.Pass ("TCP shutdown defaults verified");
end Test_TCP_Shutdown;
