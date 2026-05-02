with Ada.Exceptions;
with Ada.Strings.Fixed;
with Aion.Errors;

package body Aion.Net.Socket_Options is

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   procedure Try_Set_Boolean
     (Socket  : GNAT.Sockets.Socket_Type;
      Level   : GNAT.Sockets.Level_Type;
      Name    : GNAT.Sockets.Option_Name;
      Enabled : Boolean) is
   begin
      case Name is
         when GNAT.Sockets.Reuse_Address =>
            GNAT.Sockets.Set_Socket_Option
              (Socket, Level, (Name => GNAT.Sockets.Reuse_Address, Enabled => Enabled));
         when GNAT.Sockets.Keep_Alive =>
            GNAT.Sockets.Set_Socket_Option
              (Socket, Level, (Name => GNAT.Sockets.Keep_Alive, Enabled => Enabled));
         when GNAT.Sockets.No_Delay =>
            GNAT.Sockets.Set_Socket_Option
              (Socket, Level, (Name => GNAT.Sockets.No_Delay, Enabled => Enabled));
         when GNAT.Sockets.Broadcast =>
            GNAT.Sockets.Set_Socket_Option
              (Socket, Level, (Name => GNAT.Sockets.Broadcast, Enabled => Enabled));
         when others =>
            null;
      end case;
   exception
      when others =>
         null;
   end Try_Set_Boolean;

   function Apply_TCP
     (Socket  : GNAT.Sockets.Socket_Type;
      Options : Socket_Options) return Aion.Net.Operation_Results.Result_Type is
   begin
      Try_Set_Boolean
        (Socket, GNAT.Sockets.Socket_Level,
         GNAT.Sockets.Reuse_Address, Options.Reuse_Address);
      Try_Set_Boolean
        (Socket, GNAT.Sockets.Socket_Level,
         GNAT.Sockets.Keep_Alive, Options.Keep_Alive);
      Try_Set_Boolean
        (Socket, GNAT.Sockets.IP_Protocol_For_TCP_Level,
         GNAT.Sockets.No_Delay, Options.No_Delay);

      return Aion.Net.Operation_Results.Success (True);
   exception
      when E : others =>
         return Aion.Net.Operation_Results.Failure
           (Aion.Errors.Io_Error,
            "failed to apply TCP socket options: " & Ada.Exceptions.Exception_Message (E),
            "Aion.Net.Socket_Options.Apply_TCP");
   end Apply_TCP;

   function Apply_UDP
     (Socket  : GNAT.Sockets.Socket_Type;
      Options : Socket_Options) return Aion.Net.Operation_Results.Result_Type is
   begin
      Try_Set_Boolean
        (Socket, GNAT.Sockets.Socket_Level,
         GNAT.Sockets.Reuse_Address, Options.Reuse_Address);
      Try_Set_Boolean
        (Socket, GNAT.Sockets.Socket_Level,
         GNAT.Sockets.Broadcast, Options.Broadcast);

      return Aion.Net.Operation_Results.Success (True);
   exception
      when E : others =>
         return Aion.Net.Operation_Results.Failure
           (Aion.Errors.Io_Error,
            "failed to apply UDP socket options: " & Ada.Exceptions.Exception_Message (E),
            "Aion.Net.Socket_Options.Apply_UDP");
   end Apply_UDP;

   function Image (Options : Socket_Options) return String is
   begin
      return
        "Socket_Options(reuse=" & Boolean'Image (Options.Reuse_Address) &
        ", keep_alive=" & Boolean'Image (Options.Keep_Alive) &
        ", no_delay=" & Boolean'Image (Options.No_Delay) &
        ", broadcast=" & Boolean'Image (Options.Broadcast) &
        ", recv_timeout_ms=" & Trim (Aion.Types.Milliseconds'Image (Options.Receive_Timeout_Ms)) &
        ", send_timeout_ms=" & Trim (Aion.Types.Milliseconds'Image (Options.Send_Timeout_Ms)) & ")";
   end Image;

end Aion.Net.Socket_Options;
