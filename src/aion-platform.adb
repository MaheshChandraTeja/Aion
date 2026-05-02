package body Aion.Platform is

   function Current_OS return Operating_System is
   begin
      --  Portable default. Concrete child packages describe native backends.
      --  Keeping this deterministic makes tests reproducible across GNAT
      --  targets and cross-compilation environments.
      return OS_Portable_Unknown;
   end Current_OS;

   function Default_Backend return Backend_Kind is
   begin
      return Backend_Portable_Select;
   end Default_Backend;

   function Portable_Capabilities return Backend_Capabilities is
   begin
      return
        (Supports_Readiness      => True,
         Supports_Completion     => False,
         Supports_File_IO        => False,
         Supports_Sockets        => True,
         Supports_Timer_FD       => False,
         Requires_External_Notify => True);
   end Portable_Capabilities;

   function Image (OS : Operating_System) return String is
   begin
      case OS is
         when OS_Windows          => return "windows";
         when OS_Linux            => return "linux";
         when OS_Darwin           => return "darwin";
         when OS_BSD              => return "bsd";
         when OS_Portable_Unknown => return "portable-unknown";
      end case;
   end Image;

   function Image (Backend : Backend_Kind) return String is
   begin
      case Backend is
         when Backend_Portable_Select => return "portable-select";
         when Backend_Windows_IOCP    => return "windows-iocp";
         when Backend_Linux_Epoll     => return "linux-epoll";
         when Backend_Darwin_Kqueue   => return "darwin-kqueue";
         when Backend_BSD_Kqueue      => return "bsd-kqueue";
      end case;
   end Image;

   function Image (Capabilities : Backend_Capabilities) return String is
   begin
      return
        "Backend_Capabilities(readiness=" &
        Boolean'Image (Capabilities.Supports_Readiness) &
        ", completion=" & Boolean'Image (Capabilities.Supports_Completion) &
        ", file_io=" & Boolean'Image (Capabilities.Supports_File_IO) &
        ", sockets=" & Boolean'Image (Capabilities.Supports_Sockets) &
        ", timer_fd=" & Boolean'Image (Capabilities.Supports_Timer_FD) &
        ", external_notify=" &
        Boolean'Image (Capabilities.Requires_External_Notify) & ")";
   end Image;

end Aion.Platform;
