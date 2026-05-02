with Aion.Sleep;

package body Aion.Time is
   use type Aion.Timer_Queue.Timer_Service_Access;

   function Saturating_Multiply
     (Left  : Natural;
      Right : Natural) return Aion.Types.Milliseconds is
      Raw : constant Long_Long_Integer := Long_Long_Integer (Left) * Long_Long_Integer (Right);
   begin
      return Aion.Types.Milliseconds (Raw);
   end Saturating_Multiply;

   function Ms (Value : Natural) return Aion.Types.Milliseconds is
   begin
      return Aion.Types.Milliseconds (Value);
   end Ms;

   function Seconds (Value : Natural) return Aion.Types.Milliseconds is
   begin
      return Saturating_Multiply (Value, 1_000);
   end Seconds;

   function Minutes (Value : Natural) return Aion.Types.Milliseconds is
   begin
      return Saturating_Multiply (Value, 60_000);
   end Minutes;

   function Now return Aion.Clock.Instant is
   begin
      return Aion.Clock.Now;
   end Now;

   function Sleep_For
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Duration : Aion.Types.Milliseconds;
      Name     : String := "sleep") return Aion.Timer_Queue.Schedule_Results.Result_Type is
   begin
      return Aion.Sleep.Sleep_For (Runtime, Duration, Name);
   end Sleep_For;

   function Timer_Stats_Of
     (Runtime : in out Aion.Runtime.Runtime_Handle) return Aion.Timer_Queue.Timer_Stats is
      Service : constant Aion.Timer_Queue.Timer_Service_Access :=
        Aion.Runtime.Timers_Of (Runtime);
   begin
      if Service = null then
         return Aion.Timer_Queue.Timer_Stats'(others => <>);
      end if;

      return Aion.Timer_Queue.Stats_Of (Service.all);
   end Timer_Stats_Of;

end Aion.Time;
