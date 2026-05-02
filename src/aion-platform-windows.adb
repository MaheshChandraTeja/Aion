package body Aion.Platform.Windows is

   function Backend return Aion.Platform.Backend_Kind is
   begin
      return Aion.Platform.Backend_Windows_IOCP;
   end Backend;

   function Capabilities return Aion.Platform.Backend_Capabilities is
   begin
      return
        (Supports_Readiness       => True,
         Supports_Completion      => True,
         Supports_File_IO         => True,
         Supports_Sockets         => True,
         Supports_Timer_FD        => False,
         Requires_External_Notify => False);
   end Capabilities;

   function Description return String is
   begin
      return "Windows IOCP backend target metadata";
   end Description;

end Aion.Platform.Windows;
