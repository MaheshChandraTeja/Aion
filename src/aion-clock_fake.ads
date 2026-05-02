--  Deterministic fake clock for timer tests.
--
--  Fake_Clock is intentionally tiny: tests can advance time explicitly and use
--  the returned monotonic instants to exercise deadline math without sleeping.

with Aion.Clock;
with Aion.Types;

package Aion.Clock_Fake is

   type Fake_Clock is tagged private;

   function Create return Fake_Clock;

   procedure Advance
     (Clock : in out Fake_Clock;
      By    : Aion.Types.Milliseconds);

   procedure Set_Elapsed
     (Clock   : in out Fake_Clock;
      Elapsed : Aion.Types.Milliseconds);

   function Now (Clock : Fake_Clock) return Aion.Clock.Instant;
   function Elapsed_Of (Clock : Fake_Clock) return Aion.Types.Milliseconds;

private
   type Fake_Clock is tagged record
      Base    : Aion.Clock.Instant := Aion.Clock.Now;
      Elapsed : Aion.Types.Milliseconds := 0;
   end record;

end Aion.Clock_Fake;
