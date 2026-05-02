with Ada.Strings.Fixed;

package body Aion.IO_Token is

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   protected body Generator is
      procedure Next (Token : out IO_Token) is
      begin
         Token := Value;

         if Value = IO_Token'Last then
            Value := 1;
         else
            Value := Value + 1;
         end if;
      end Next;

      function Current return IO_Token is
      begin
         return Value;
      end Current;
   end Generator;

   function Is_Valid (Token : IO_Token) return Boolean is
   begin
      return Token /= No_Token;
   end Is_Valid;

   function Image (Token : IO_Token) return String is
   begin
      if Token = No_Token then
         return "io-token:none";
      end if;

      return "io-token:" & Trim (IO_Token'Image (Token));
   end Image;

end Aion.IO_Token;
