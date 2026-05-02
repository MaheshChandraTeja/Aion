with Aion.Clock;
with Aion.Clock_Fake;
with Aion.Types;
with Test_Support;

procedure Test_Fake_Clock is
   use type Aion.Clock.Instant;
   use type Aion.Types.Milliseconds;
   Clock : Aion.Clock_Fake.Fake_Clock := Aion.Clock_Fake.Create;
   First : constant Aion.Clock.Instant := Aion.Clock_Fake.Now (Clock);
   Later : Aion.Clock.Instant;
begin
   Test_Support.Section ("fake clock");

   Aion.Clock_Fake.Advance (Clock, 250);
   Later := Aion.Clock_Fake.Now (Clock);

   Test_Support.Assert (Aion.Clock_Fake.Elapsed_Of (Clock) = 250, "fake clock elapsed time advances");
   Test_Support.Assert (Later > First, "fake clock instant moves forward");

   Test_Support.Pass ("fake clock supports deterministic deadline tests");
end Test_Fake_Clock;
