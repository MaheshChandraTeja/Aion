--  Async sleep helpers.
--
--  Sleep_For schedules a timer on the runtime-owned timer service and returns
--  a future-backed timer handle. Waiting on the future is explicit; scheduling
--  itself does not block the runtime worker.

with Aion.Clock;
with Aion.Runtime;
with Aion.Timer_Queue;
with Aion.Types;

package Aion.Sleep is

   function Sleep_For
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Duration : Aion.Types.Milliseconds;
      Name     : String := "sleep") return Aion.Timer_Queue.Schedule_Results.Result_Type;

   function Sleep_Until
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Deadline : Aion.Clock.Instant;
      Name     : String := "sleep-until") return Aion.Timer_Queue.Schedule_Results.Result_Type;

   --  Explicit blocking bridge for command-line demos and tests.
   procedure Blocking_Sleep_For (Duration : Aion.Types.Milliseconds);

   --  Convenience: schedule the timer and wait for its future.
   function Wait_For
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Duration : Aion.Types.Milliseconds) return Aion.Timer_Queue.Timer_Futures.Value_Results.Result_Type;

end Aion.Sleep;
