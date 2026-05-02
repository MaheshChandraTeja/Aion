--  Async TCP stream API built on Aion.Runtime futures and the runtime-owned
--  reactor service. Public operations return typed futures; blocking socket
--  calls are isolated inside runtime jobs rather than caller code.

with Ada.Strings.Unbounded;
with GNAT.Sockets;
with Aion.Future;
with Aion.IO_Resource;
with Aion.Net.Address;
with Aion.Net.Socket_Options;
with Aion.Reactor;
with Aion.Result;
with Aion.Runtime;
with Aion.Types;

package Aion.Net.TCP_Stream is

   package US renames Ada.Strings.Unbounded;

   type TCP_Stream is record
      Socket   : GNAT.Sockets.Socket_Type := GNAT.Sockets.No_Socket;
      Peer     : Aion.Net.Address.Network_Address :=
        Aion.Net.Address.Localhost (0);
      Resource : Aion.IO_Resource.IO_Resource := Aion.IO_Resource.Null_Resource;
      Open     : Boolean := False;
      Name     : US.Unbounded_String := US.Null_Unbounded_String;
   end record;

   Null_Stream : constant TCP_Stream :=
     (Socket   => GNAT.Sockets.No_Socket,
      Peer     => Aion.Net.Address.Localhost (0),
      Resource => Aion.IO_Resource.Null_Resource,
      Open     => False,
      Name     => US.Null_Unbounded_String);

   package Stream_Results is new Aion.Result.Generic_Result (TCP_Stream);
   package Stream_Futures is new Aion.Future.Generic_Future (TCP_Stream);

   function Async_Connect
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Address : Aion.Net.Address.Network_Address;
      Options : Aion.Net.Socket_Options.Socket_Options :=
        Aion.Net.Socket_Options.Default_TCP;
      Name    : String := "tcp-connect") return Stream_Futures.Future_Handle;

   function Async_Read
     (Runtime   : in out Aion.Runtime.Runtime_Handle;
      Stream    : TCP_Stream;
      Max_Bytes : Aion.Net.Buffer_Length := Aion.Net.Max_Buffer_Size;
      Timeout   : Aion.Types.Milliseconds := 0;
      Name      : String := "tcp-read") return Aion.Net.Buffer_Futures.Future_Handle;

   function Async_Write
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Stream  : TCP_Stream;
      Buffer  : Aion.Net.Net_Buffer;
      Timeout : Aion.Types.Milliseconds := 0;
      Name    : String := "tcp-write") return Aion.Net.Count_Futures.Future_Handle;

   function Close
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Stream  : in out TCP_Stream) return Aion.Net.Operation_Results.Result_Type;

   function Is_Open (Stream : TCP_Stream) return Boolean;
   function Name_Of (Stream : TCP_Stream) return String;
   function Peer_Of (Stream : TCP_Stream) return Aion.Net.Address.Network_Address;
   function Resource_Of (Stream : TCP_Stream) return Aion.IO_Resource.IO_Resource;
   function Image (Stream : TCP_Stream) return String;

   --  Internal construction hook used by TCP listener after accept. It remains
   --  public so Module 6 files stay decoupled without creating a hidden child
   --  package. Application code should prefer Async_Connect or Listener.Accept.
   function From_Accepted_Socket
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Socket  : GNAT.Sockets.Socket_Type;
      Peer    : Aion.Net.Address.Network_Address;
      Name    : String := "tcp-accepted") return Stream_Results.Result_Type;

   function From_Accepted_Socket
     (Reactor : not null Aion.Reactor.Reactor_Service_Access;
      Socket  : GNAT.Sockets.Socket_Type;
      Peer    : Aion.Net.Address.Network_Address;
      Name    : String := "tcp-accepted") return Stream_Results.Result_Type;

end Aion.Net.TCP_Stream;
