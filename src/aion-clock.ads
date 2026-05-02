--  Monotonic clock abstraction for Aion timers.
--
--  This package deliberately uses Ada.Real_Time instead of Ada.Calendar so
--  runtime timers are not affected by wall-clock jumps, NTP corrections, or
--  the usual temporal nonsense humans bolt onto computers.

with Ada.Real_Time;
with Aion.Types;

package Aion.Clock is

   type Instant is private;

   function Now return Instant;
   function Epoch return Instant;

   function Add
     (Base  : Instant;
      Offset : Aion.Types.Milliseconds) return Instant;

   function Subtract
     (Left  : Instant;
      Right : Instant) return Duration;

   function Time_Until (Deadline : Instant) return Duration;
   function Has_Passed (Deadline : Instant) return Boolean;

   function From_Epoch_Offset
     (Offset : Aion.Types.Milliseconds) return Instant;

   function Milliseconds_Between
     (Left  : Instant;
      Right : Instant) return Aion.Types.Milliseconds;

   function Image (Value : Instant) return String;

   function "<"  (Left, Right : Instant) return Boolean;
   function "<=" (Left, Right : Instant) return Boolean;
   function ">"  (Left, Right : Instant) return Boolean;
   function ">=" (Left, Right : Instant) return Boolean;
   function "="  (Left, Right : Instant) return Boolean;

private

   type Instant is record
      Value : Ada.Real_Time.Time := Ada.Real_Time.Time_First;
   end record;

end Aion.Clock;
