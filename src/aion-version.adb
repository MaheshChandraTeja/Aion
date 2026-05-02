with Ada.Strings.Fixed;

package body Aion.Version is

   function Trim_Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Trim_Image;

   function Semver return String is
      Base : constant String :=
        Trim_Image (Major) & "." & Trim_Image (Minor) & "." & Trim_Image (Patch);
   begin
      if Prerelease'Length > 0 then
         return Base & "-" & Prerelease;
      else
         return Base;
      end if;
   end Semver;

   function Full return String is
   begin
      if Build'Length > 0 then
         return Semver & "+" & Build;
      else
         return Semver;
      end if;
   end Full;

end Aion.Version;
