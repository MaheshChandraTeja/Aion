package body Aion.Deadline is

   function From_Instant (Instant : Aion.Clock.Instant) return Deadline is
   begin
      return (Due => Instant);
   end From_Instant;

   function After (Duration : Aion.Types.Milliseconds) return Deadline is
   begin
      return (Due => Aion.Clock.Add (Aion.Clock.Now, Duration));
   end After;

   function Instant_Of (Item : Deadline) return Aion.Clock.Instant is
   begin
      return Item.Due;
   end Instant_Of;

   function Has_Expired (Item : Deadline) return Boolean is
   begin
      return Aion.Clock.Has_Passed (Item.Due);
   end Has_Expired;

   function Remaining (Item : Deadline) return Duration is
   begin
      return Aion.Clock.Time_Until (Item.Due);
   end Remaining;

   function Extend
     (Item : Deadline;
      By   : Aion.Types.Milliseconds) return Deadline is
   begin
      return (Due => Aion.Clock.Add (Item.Due, By));
   end Extend;

   function Image (Item : Deadline) return String is
   begin
      return "deadline[due=" & Aion.Clock.Image (Item.Due) & "]";
   end Image;

end Aion.Deadline;
