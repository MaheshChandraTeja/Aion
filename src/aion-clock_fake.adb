package body Aion.Clock_Fake is
   use type Aion.Types.Milliseconds;

   function Create return Fake_Clock is
   begin
      return (Base => Aion.Clock.Now, Elapsed => 0);
   end Create;

   procedure Advance
     (Clock : in out Fake_Clock;
      By    : Aion.Types.Milliseconds) is
   begin
      if Aion.Types.Milliseconds'Last - Clock.Elapsed < By then
         Clock.Elapsed := Aion.Types.Milliseconds'Last;
      else
         Clock.Elapsed := Clock.Elapsed + By;
      end if;
   end Advance;

   procedure Set_Elapsed
     (Clock   : in out Fake_Clock;
      Elapsed : Aion.Types.Milliseconds) is
   begin
      Clock.Elapsed := Elapsed;
   end Set_Elapsed;

   function Now (Clock : Fake_Clock) return Aion.Clock.Instant is
   begin
      return Aion.Clock.Add (Clock.Base, Clock.Elapsed);
   end Now;

   function Elapsed_Of (Clock : Fake_Clock) return Aion.Types.Milliseconds is
   begin
      return Clock.Elapsed;
   end Elapsed_Of;

end Aion.Clock_Fake;
