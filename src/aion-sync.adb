with Ada.Strings.Fixed;

package body Aion.Sync is
   use type Interfaces.Unsigned_64;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function U64_Image (Value : Interfaces.Unsigned_64) return String is
   begin
      return Trim (Interfaces.Unsigned_64'Image (Value));
   end U64_Image;

   protected body Atomic_Counter is
      procedure Increment is
      begin
         Current := Current + 1;
      end Increment;

      procedure Add (Amount : Interfaces.Unsigned_64) is
      begin
         Current := Current + Amount;
      end Add;

      procedure Decrement is
      begin
         if Current > 0 then
            Current := Current - 1;
         end if;
      end Decrement;

      procedure Reset (To : Interfaces.Unsigned_64 := 0) is
      begin
         Current := To;
      end Reset;

      function Value return Interfaces.Unsigned_64 is
      begin
         return Current;
      end Value;
   end Atomic_Counter;

   function Image (Stats : Primitive_Stats) return String is
   begin
      return "waiters=" & Trim (Natural'Image (Stats.Waiters)) &
        ", wakeups=" & U64_Image (Stats.Wakeups) &
        ", acquisitions=" & U64_Image (Stats.Acquisitions) &
        ", releases=" & U64_Image (Stats.Releases) &
        ", cancellations=" & U64_Image (Stats.Cancellations) &
        ", failures=" & U64_Image (Stats.Failures);
   end Image;

end Aion.Sync;
