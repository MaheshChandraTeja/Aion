--  Internal helpers shared by Aion modules.
--  This package is public in the source tree so child modules can reuse it,
--  but it is not part of the stable user-facing API contract.

with Aion.Types;

package Aion.Internal is

   procedure Set_Debug_Enabled (Enabled : Boolean);
   function Debug_Enabled return Boolean;

   function Clamp_Worker_Count
     (Workers : Natural) return Aion.Types.Worker_Count;

   function Is_Blank (Value : String) return Boolean;

   function Safe_Name
     (Value    : String;
      Fallback : String := "aion") return String;

   function Min (Left, Right : Natural) return Natural;
   function Max (Left, Right : Natural) return Natural;

end Aion.Internal;
