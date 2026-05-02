--  Deadline helpers built on the monotonic Aion clock.

with Aion.Clock;
with Aion.Types;

package Aion.Deadline is

   type Deadline is private;

   function From_Instant (Instant : Aion.Clock.Instant) return Deadline;
   function After (Duration : Aion.Types.Milliseconds) return Deadline;

   function Instant_Of (Item : Deadline) return Aion.Clock.Instant;
   function Has_Expired (Item : Deadline) return Boolean;
   function Remaining (Item : Deadline) return Duration;

   function Extend
     (Item : Deadline;
      By   : Aion.Types.Milliseconds) return Deadline;

   function Image (Item : Deadline) return String;

private
   type Deadline is record
      Due : Aion.Clock.Instant := Aion.Clock.Epoch;
   end record;

end Aion.Deadline;
