--  Async TCP listener API.

with Ada.Strings.Unbounded;
with GNAT.Sockets;
with Aion.IO_Resource;
with Aion.Net.Address;
with Aion.Net.Socket_Options;
with Aion.Net.TCP_Stream;
with Aion.Result;
with Aion.Runtime;
with Aion.Types;

package Aion.Net.TCP_Listener is

   package US renames Ada.Strings.Unbounded;

   type TCP_Listener is record
      Socket   : GNAT.Sockets.Socket_Type := GNAT.Sockets.No_Socket;
      Local    : Aion.Net.Address.Network_Address := Aion.Net.Address.Localhost (0);
      Resource : Aion.IO_Resource.IO_Resource := Aion.IO_Resource.Null_Resource;
      Open     : Boolean := False;
      Name     : US.Unbounded_String := US.Null_Unbounded_String;
   end record;

   Null_Listener : constant TCP_Listener :=
     (Socket   => GNAT.Sockets.No_Socket,
      Local    => Aion.Net.Address.Localhost (0),
      Resource => Aion.IO_Resource.Null_Resource,
      Open     => False,
      Name     => US.Null_Unbounded_String);

   package Listener_Results is new Aion.Result.Generic_Result (TCP_Listener);

   function Bind
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Address : Aion.Net.Address.Network_Address;
      Options : Aion.Net.Socket_Options.Socket_Options :=
        Aion.Net.Socket_Options.Default_TCP;
      Backlog : Positive := 128;
      Name    : String := "tcp-listener") return Listener_Results.Result_Type;

   function Async_Accept
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Listener : TCP_Listener;
      Timeout  : Aion.Types.Milliseconds := 0;
      Name     : String := "tcp-accept")
      return Aion.Net.TCP_Stream.Stream_Futures.Future_Handle;

   function Close
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Listener : in out TCP_Listener) return Aion.Net.Operation_Results.Result_Type;

   function Is_Open (Listener : TCP_Listener) return Boolean;
   function Local_Address_Of
     (Listener : TCP_Listener) return Aion.Net.Address.Network_Address;
   function Resource_Of (Listener : TCP_Listener) return Aion.IO_Resource.IO_Resource;
   function Image (Listener : TCP_Listener) return String;

end Aion.Net.TCP_Listener;
