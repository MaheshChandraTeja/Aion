--  Async interval/ticker built on Aion.Timer_Queue.

with Ada.Strings.Unbounded;
with Aion.Clock;
with Aion.Result;
with Aion.Timer_Queue;
with Aion.Types;

package Aion.Interval is

   package US renames Ada.Strings.Unbounded;

   type Interval is record
      Service       : Aion.Timer_Queue.Timer_Service_Access := null;
      Period        : Aion.Types.Milliseconds := 0;
      Name          : US.Unbounded_String := US.Null_Unbounded_String;
      Next_Deadline : Aion.Clock.Instant := Aion.Clock.Epoch;
      Last_Timer    : Aion.Timer_Queue.Timer_Handle := Aion.Timer_Queue.Null_Timer;
      Tick_Count    : Natural := 0;
   end record;

   package Interval_Results is new Aion.Result.Generic_Result (Interval);

   function Every
     (Service : not null Aion.Timer_Queue.Timer_Service_Access;
      Period  : Aion.Types.Milliseconds;
      Name    : String := "interval") return Interval_Results.Result_Type;

   function Tick
     (Ticker : in out Interval) return Aion.Timer_Queue.Schedule_Results.Result_Type;

   function Cancel_Last (Ticker : in out Interval)
      return Aion.Timer_Queue.Operation_Results.Result_Type;

   function Is_Valid (Ticker : Interval) return Boolean;
   function Period_Of (Ticker : Interval) return Aion.Types.Milliseconds;
   function Next_Deadline_Of (Ticker : Interval) return Aion.Clock.Instant;
   function Ticks_Of (Ticker : Interval) return Natural;
   function Image (Ticker : Interval) return String;

end Aion.Interval;
