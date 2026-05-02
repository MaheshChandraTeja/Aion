--  Public time facade for Aion.

with Aion.Clock;
with Aion.Runtime;
with Aion.Timer_Queue;
with Aion.Types;

package Aion.Time is

   function Ms (Value : Natural) return Aion.Types.Milliseconds;
   function Seconds (Value : Natural) return Aion.Types.Milliseconds;
   function Minutes (Value : Natural) return Aion.Types.Milliseconds;

   function Now return Aion.Clock.Instant;

   function Sleep_For
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Duration : Aion.Types.Milliseconds;
      Name     : String := "sleep") return Aion.Timer_Queue.Schedule_Results.Result_Type;

   function Timer_Stats_Of
     (Runtime : in out Aion.Runtime.Runtime_Handle) return Aion.Timer_Queue.Timer_Stats;

end Aion.Time;
