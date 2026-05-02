--  Platform/backend selection metadata for the Aion reactor.
--
--  Module 5 ships a production-ready portable readiness backend that is used
--  by the runtime today. OS-specific packages expose the intended native
--  backend metadata so later low-level bindings can plug in without changing
--  public reactor APIs.

package Aion.Platform is
   pragma Preelaborate;

   type Operating_System is
     (OS_Windows,
      OS_Linux,
      OS_Darwin,
      OS_BSD,
      OS_Portable_Unknown);

   type Backend_Kind is
     (Backend_Portable_Select,
      Backend_Windows_IOCP,
      Backend_Linux_Epoll,
      Backend_Darwin_Kqueue,
      Backend_BSD_Kqueue);

   type Backend_Capabilities is record
      Supports_Readiness : Boolean := True;
      Supports_Completion : Boolean := False;
      Supports_File_IO : Boolean := False;
      Supports_Sockets : Boolean := True;
      Supports_Timer_FD : Boolean := False;
      Requires_External_Notify : Boolean := True;
   end record;

   function Current_OS return Operating_System;
   function Default_Backend return Backend_Kind;
   function Portable_Capabilities return Backend_Capabilities;
   function Image (OS : Operating_System) return String;
   function Image (Backend : Backend_Kind) return String;
   function Image (Capabilities : Backend_Capabilities) return String;
end Aion.Platform;
