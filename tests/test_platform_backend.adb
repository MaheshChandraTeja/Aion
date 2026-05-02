with Aion.Platform;
with Aion.Platform.Windows;
with Aion.Platform.Linux;
with Aion.Platform.Darwin;
with Test_Support;

procedure Test_Platform_Backend is
   use type Aion.Platform.Backend_Kind;
   Portable : constant Aion.Platform.Backend_Capabilities :=
     Aion.Platform.Portable_Capabilities;
begin
   Test_Support.Section ("platform backend metadata");
   Test_Support.Assert
     (Aion.Platform.Default_Backend = Aion.Platform.Backend_Portable_Select,
      "module 5 should default to portable backend metadata");
   Test_Support.Assert (Portable.Supports_Readiness, "portable backend supports readiness events");
   Test_Support.Assert
     (Aion.Platform.Windows.Backend = Aion.Platform.Backend_Windows_IOCP,
      "windows metadata should advertise IOCP target");
   Test_Support.Assert
     (Aion.Platform.Linux.Backend = Aion.Platform.Backend_Linux_Epoll,
      "linux metadata should advertise epoll target");
   Test_Support.Assert
     (Aion.Platform.Darwin.Backend = Aion.Platform.Backend_Darwin_Kqueue,
      "darwin metadata should advertise kqueue target");
   Test_Support.Pass (Aion.Platform.Image (Portable));
end Test_Platform_Backend;
