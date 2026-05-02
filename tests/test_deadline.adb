with Aion.Deadline;
with Aion.Sleep;
with Test_Support;

procedure Test_Deadline is
   Item : constant Aion.Deadline.Deadline := Aion.Deadline.After (5);
begin
   Test_Support.Section ("deadline");

   Test_Support.Assert (not Aion.Deadline.Has_Expired (Item), "fresh deadline is not expired");
   Aion.Sleep.Blocking_Sleep_For (20);
   Test_Support.Assert (Aion.Deadline.Has_Expired (Item), "deadline expires after sleep");

   Test_Support.Pass ("deadline helpers use monotonic clock");
end Test_Deadline;
