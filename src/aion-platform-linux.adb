package body Aion.Platform.Linux is

   function Backend return Aion.Platform.Backend_Kind is
   begin
      return Aion.Platform.Backend_Linux_Epoll;
   end Backend;

   function Capabilities return Aion.Platform.Backend_Capabilities is
   begin
      return
        (Supports_Readiness       => True,
         Supports_Completion      => False,
         Supports_File_IO         => False,
         Supports_Sockets         => True,
         Supports_Timer_FD        => True,
         Requires_External_Notify => False);
   end Capabilities;

   function Description return String is
   begin
      return "Linux epoll backend target metadata";
   end Description;

end Aion.Platform.Linux;
