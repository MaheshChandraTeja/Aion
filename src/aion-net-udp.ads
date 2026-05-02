--  Async UDP socket API built on Aion.Runtime futures and reactor readiness.

with Ada.Strings.Unbounded;
with GNAT.Sockets;
with Aion.Future;
with Aion.IO_Resource;
with Aion.Net.Address;
with Aion.Net.Socket_Options;
with Aion.Result;
with Aion.Runtime;
with Aion.Types;

package Aion.Net.UDP is

   package US renames Ada.Strings.Unbounded;

   type Datagram is record
      Payload : Aion.Net.Net_Buffer := Aion.Net.Empty_Buffer;
      Peer    : Aion.Net.Address.Network_Address := Aion.Net.Address.Localhost (0);
   end record;

   type UDP_Socket is record
      Socket   : GNAT.Sockets.Socket_Type := GNAT.Sockets.No_Socket;
      Local    : Aion.Net.Address.Network_Address := Aion.Net.Address.Localhost (0);
      Resource : Aion.IO_Resource.IO_Resource := Aion.IO_Resource.Null_Resource;
      Open     : Boolean := False;
      Name     : US.Unbounded_String := US.Null_Unbounded_String;
   end record;

   Null_Socket : constant UDP_Socket :=
     (Socket   => GNAT.Sockets.No_Socket,
      Local    => Aion.Net.Address.Localhost (0),
      Resource => Aion.IO_Resource.Null_Resource,
      Open     => False,
      Name     => US.Null_Unbounded_String);

   package Socket_Results is new Aion.Result.Generic_Result (UDP_Socket);
   package Datagram_Futures is new Aion.Future.Generic_Future (Datagram);

   function Bind
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Address : Aion.Net.Address.Network_Address;
      Options : Aion.Net.Socket_Options.Socket_Options :=
        Aion.Net.Socket_Options.Default_UDP;
      Name    : String := "udp-socket") return Socket_Results.Result_Type;

   function Async_Send_To
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Socket  : UDP_Socket;
      Peer    : Aion.Net.Address.Network_Address;
      Payload : Aion.Net.Net_Buffer;
      Timeout : Aion.Types.Milliseconds := 0;
      Name    : String := "udp-send") return Aion.Net.Count_Futures.Future_Handle;

   function Async_Receive_From
     (Runtime   : in out Aion.Runtime.Runtime_Handle;
      Socket    : UDP_Socket;
      Max_Bytes : Aion.Net.Buffer_Length := Aion.Net.Max_Buffer_Size;
      Timeout   : Aion.Types.Milliseconds := 0;
      Name      : String := "udp-receive") return Datagram_Futures.Future_Handle;

   function Close
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Socket  : in out UDP_Socket) return Aion.Net.Operation_Results.Result_Type;

   function Is_Open (Socket : UDP_Socket) return Boolean;
   function Local_Address_Of
     (Socket : UDP_Socket) return Aion.Net.Address.Network_Address;
   function Resource_Of (Socket : UDP_Socket) return Aion.IO_Resource.IO_Resource;
   function Image (Socket : UDP_Socket) return String;
   function Image (Item : Datagram) return String;

end Aion.Net.UDP;
