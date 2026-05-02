--  Version metadata for Aion.

package Aion.Version is
   pragma Preelaborate;

   Major : constant Natural := 0;
   Minor : constant Natural := 1;
   Patch : constant Natural := 0;

   Prerelease : constant String := "module1";
   Build      : constant String := "";

   function Semver return String;
   function Full return String;
end Aion.Version;
