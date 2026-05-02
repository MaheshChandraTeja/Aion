with Ada.Characters.Latin_1;

package body Aion.Internal is

   protected Debug_State is
      procedure Set (Enabled : Boolean);
      function Get return Boolean;
   private
      Current : Boolean := False;
   end Debug_State;

   protected body Debug_State is
      procedure Set (Enabled : Boolean) is
      begin
         Current := Enabled;
      end Set;

      function Get return Boolean is
      begin
         return Current;
      end Get;
   end Debug_State;

   procedure Set_Debug_Enabled (Enabled : Boolean) is
   begin
      Debug_State.Set (Enabled);
   end Set_Debug_Enabled;

   function Debug_Enabled return Boolean is
   begin
      return Debug_State.Get;
   end Debug_Enabled;

   function Clamp_Worker_Count
     (Workers : Natural) return Aion.Types.Worker_Count is
   begin
      if Workers < Aion.Types.Worker_Count'First then
         return Aion.Types.Worker_Count'First;
      elsif Workers > Aion.Types.Worker_Count'Last then
         return Aion.Types.Worker_Count'Last;
      else
         return Aion.Types.Worker_Count (Workers);
      end if;
   end Clamp_Worker_Count;

   function Is_Blank (Value : String) return Boolean is
      use Ada.Characters.Latin_1;
   begin
      for Ch of Value loop
         if Ch /= ' ' and then Ch /= HT and then Ch /= LF and then Ch /= CR then
            return False;
         end if;
      end loop;

      return True;
   end Is_Blank;

   function Safe_Name
     (Value    : String;
      Fallback : String := "aion") return String is
   begin
      if Is_Blank (Value) then
         return Fallback;
      else
         return Value;
      end if;
   end Safe_Name;

   function Min (Left, Right : Natural) return Natural is
   begin
      if Left < Right then
         return Left;
      else
         return Right;
      end if;
   end Min;

   function Max (Left, Right : Natural) return Natural is
   begin
      if Left > Right then
         return Left;
      else
         return Right;
      end if;
   end Max;

end Aion.Internal;
