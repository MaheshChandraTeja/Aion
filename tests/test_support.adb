with Ada.Text_IO;
with Ada.Strings.Fixed;

package body Test_Support is
   use type Interfaces.Unsigned_64;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function U64_Image (Value : Interfaces.Unsigned_64) return String is
   begin
      return Trim (Interfaces.Unsigned_64'Image (Value));
   end U64_Image;

   procedure Section (Name : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("== " & Name & " ==");
   end Section;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         raise Program_Error with "assertion failed: " & Message;
      end if;
   end Assert;

   procedure Assert_U64_Equals
     (Expected : Interfaces.Unsigned_64;
      Actual   : Interfaces.Unsigned_64;
      Message  : String) is
   begin
      Assert
        (Expected = Actual,
         Message & " expected=" & U64_Image (Expected) & " actual=" & U64_Image (Actual));
   end Assert_U64_Equals;

   procedure Assert_U64_At_Least
     (Minimum : Interfaces.Unsigned_64;
      Actual  : Interfaces.Unsigned_64;
      Message : String) is
   begin
      Assert
        (Actual >= Minimum,
         Message & " minimum=" & U64_Image (Minimum) & " actual=" & U64_Image (Actual));
   end Assert_U64_At_Least;

   procedure Pass (Message : String) is
   begin
      Ada.Text_IO.Put_Line ("PASS: " & Message);
   end Pass;

end Test_Support;
