with Ada.Text_IO;
with Aion.Platform;
with Aion.Platform.Windows;
with Aion.Platform.Linux;
with Aion.Platform.Darwin;

procedure Reactor_Backend_Demo is
begin
   Ada.Text_IO.Put_Line ("Aion Reactor Backend Metadata");
   Ada.Text_IO.Put_Line ("default backend: " &
     Aion.Platform.Image (Aion.Platform.Default_Backend));
   Ada.Text_IO.Put_Line ("portable: " &
     Aion.Platform.Image (Aion.Platform.Portable_Capabilities));
   Ada.Text_IO.Put_Line ("windows: " &
     Aion.Platform.Image (Aion.Platform.Windows.Backend));
   Ada.Text_IO.Put_Line ("linux: " &
     Aion.Platform.Image (Aion.Platform.Linux.Backend));
   Ada.Text_IO.Put_Line ("darwin: " &
     Aion.Platform.Image (Aion.Platform.Darwin.Backend));
end Reactor_Backend_Demo;
