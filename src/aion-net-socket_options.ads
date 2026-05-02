--  Socket option configuration for Aion networking.

with GNAT.Sockets;
with Aion.Types;

package Aion.Net.Socket_Options is

   type Socket_Options is record
      Reuse_Address      : Boolean := True;
      Keep_Alive         : Boolean := False;
      No_Delay           : Boolean := True;
      Broadcast          : Boolean := False;
      Receive_Timeout_Ms : Aion.Types.Milliseconds := 0;
      Send_Timeout_Ms    : Aion.Types.Milliseconds := 0;
   end record;

   Default_TCP : constant Socket_Options :=
     (Reuse_Address      => True,
      Keep_Alive         => True,
      No_Delay           => True,
      Broadcast          => False,
      Receive_Timeout_Ms => 0,
      Send_Timeout_Ms    => 0);

   Default_UDP : constant Socket_Options :=
     (Reuse_Address      => True,
      Keep_Alive         => False,
      No_Delay           => False,
      Broadcast          => False,
      Receive_Timeout_Ms => 0,
      Send_Timeout_Ms    => 0);

   function Apply_TCP
     (Socket  : GNAT.Sockets.Socket_Type;
      Options : Socket_Options) return Aion.Net.Operation_Results.Result_Type;

   function Apply_UDP
     (Socket  : GNAT.Sockets.Socket_Type;
      Options : Socket_Options) return Aion.Net.Operation_Results.Result_Type;

   function Image (Options : Socket_Options) return String;

end Aion.Net.Socket_Options;
