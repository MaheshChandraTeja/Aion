package Aion.Platform.Linux is
   pragma Preelaborate;

   function Backend return Aion.Platform.Backend_Kind;
   function Capabilities return Aion.Platform.Backend_Capabilities;
   function Description return String;
end Aion.Platform.Linux;
