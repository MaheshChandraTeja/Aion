--  TCP facade package for Aion.Net.

with Aion.Net.Address;
with Aion.Net.Socket_Options;
with Aion.Net.TCP_Listener;
with Aion.Net.TCP_Stream;
with Aion.Runtime;

package Aion.Net.TCP is
   pragma Elaborate_Body;

   subtype TCP_Stream is Aion.Net.TCP_Stream.TCP_Stream;
   subtype TCP_Listener is Aion.Net.TCP_Listener.TCP_Listener;

   function Connect
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Address : Aion.Net.Address.Network_Address;
      Options : Aion.Net.Socket_Options.Socket_Options :=
        Aion.Net.Socket_Options.Default_TCP;
      Name    : String := "tcp-connect")
      return Aion.Net.TCP_Stream.Stream_Futures.Future_Handle
      renames Aion.Net.TCP_Stream.Async_Connect;

   function Bind
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Address : Aion.Net.Address.Network_Address;
      Options : Aion.Net.Socket_Options.Socket_Options :=
        Aion.Net.Socket_Options.Default_TCP;
      Backlog : Positive := 128;
      Name    : String := "tcp-listener")
      return Aion.Net.TCP_Listener.Listener_Results.Result_Type
      renames Aion.Net.TCP_Listener.Bind;

end Aion.Net.TCP;
