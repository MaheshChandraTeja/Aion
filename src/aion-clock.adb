with Ada.Strings.Fixed;

package body Aion.Clock is
   use type Ada.Real_Time.Time;
   use type Ada.Real_Time.Time_Span;
   use type Aion.Types.Milliseconds;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function To_Time_Span
     (Value : Aion.Types.Milliseconds) return Ada.Real_Time.Time_Span is
      Max_Int : constant Aion.Types.Milliseconds :=
        Aion.Types.Milliseconds (Integer'Last);
   begin
      if Value = 0 then
         return Ada.Real_Time.Time_Span_Zero;
      elsif Value > Max_Int then
         return Ada.Real_Time.Milliseconds (Integer'Last);
      else
         return Ada.Real_Time.Milliseconds (Integer (Value));
      end if;
   end To_Time_Span;

   function From_Duration (Value : Duration) return Aion.Types.Milliseconds is
      function Scale return Duration is (1000.0);
      Max_Convertible : constant Duration := Duration'Last / Scale;
   begin
      if Value <= 0.0 then
         return 0;
      elsif Value >= Max_Convertible then
         return Aion.Types.Milliseconds'Last;
      else
         return Aion.Types.Milliseconds (Long_Long_Integer (Value * 1000.0));
      end if;
   end From_Duration;

   function Now return Instant is
   begin
      return (Value => Ada.Real_Time.Clock);
   end Now;

   function Epoch return Instant is
   begin
      return (Value => Ada.Real_Time.Time_First);
   end Epoch;

   function Add
     (Base  : Instant;
      Offset : Aion.Types.Milliseconds) return Instant is
   begin
      return (Value => Base.Value + To_Time_Span (Offset));
   end Add;

   function Subtract
     (Left  : Instant;
      Right : Instant) return Duration is
   begin
      return Ada.Real_Time.To_Duration (Left.Value - Right.Value);
   end Subtract;

   function Time_Until (Deadline : Instant) return Duration is
      Span : constant Ada.Real_Time.Time_Span := Deadline.Value - Ada.Real_Time.Clock;
   begin
      if Span <= Ada.Real_Time.Time_Span_Zero then
         return 0.0;
      end if;

      return Ada.Real_Time.To_Duration (Span);
   end Time_Until;

   function Has_Passed (Deadline : Instant) return Boolean is
   begin
      return Ada.Real_Time.Clock >= Deadline.Value;
   end Has_Passed;

   function From_Epoch_Offset
     (Offset : Aion.Types.Milliseconds) return Instant is
   begin
      return Add (Epoch, Offset);
   end From_Epoch_Offset;

   function Milliseconds_Between
     (Left  : Instant;
      Right : Instant) return Aion.Types.Milliseconds is
   begin
      return From_Duration (abs Subtract (Left, Right));
   end Milliseconds_Between;

   function Image (Value : Instant) return String is
      Offset : constant Duration := Subtract (Value, Epoch);
   begin
      return "instant(epoch_offset_s=" & Trim (Duration'Image (Offset)) & ")";
   end Image;

   function "<"  (Left, Right : Instant) return Boolean is
   begin
      return Left.Value < Right.Value;
   end "<";

   function "<=" (Left, Right : Instant) return Boolean is
   begin
      return Left.Value <= Right.Value;
   end "<=";

   function ">"  (Left, Right : Instant) return Boolean is
   begin
      return Left.Value > Right.Value;
   end ">";

   function ">=" (Left, Right : Instant) return Boolean is
   begin
      return Left.Value >= Right.Value;
   end ">=";

   function "="  (Left, Right : Instant) return Boolean is
   begin
      return Left.Value = Right.Value;
   end "=";

end Aion.Clock;
