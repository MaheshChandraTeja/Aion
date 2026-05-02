with Ada.Strings.Fixed;
with Aion.Errors;

package body Aion.Interval is
   use type Aion.Timer_Queue.Timer_Service_Access;
   use type Aion.Types.Milliseconds;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function Every
     (Service : not null Aion.Timer_Queue.Timer_Service_Access;
      Period  : Aion.Types.Milliseconds;
      Name    : String := "interval") return Interval_Results.Result_Type is
   begin
      if Period = 0 then
         return Interval_Results.Failure
           (Aion.Errors.Invalid_Argument,
            "interval period must be greater than zero milliseconds",
            "Aion.Interval.Every");
      end if;

      if Aion.Timer_Queue.Is_Stopping (Service.all) then
         return Interval_Results.Failure
           (Aion.Errors.Invalid_State,
            "timer service is stopping",
            "Aion.Interval.Every");
      end if;

      return Interval_Results.Success
        ((Service       => Service,
          Period        => Period,
          Name          => US.To_Unbounded_String (Name),
          Next_Deadline => Aion.Clock.Add (Aion.Clock.Now, Period),
          Last_Timer    => Aion.Timer_Queue.Null_Timer,
          Tick_Count    => 0));
   end Every;

   function Tick
     (Ticker : in out Interval) return Aion.Timer_Queue.Schedule_Results.Result_Type is
      Result : Aion.Timer_Queue.Schedule_Results.Result_Type;
   begin
      if not Is_Valid (Ticker) then
         return Aion.Timer_Queue.Schedule_Results.Failure
           (Aion.Errors.Invalid_State,
            "interval is not valid",
            "Aion.Interval.Tick");
      end if;

      Result := Aion.Timer_Queue.Schedule_At
        (Ticker.Service,
         Ticker.Next_Deadline,
         US.To_String (Ticker.Name) & "-tick");

      if Aion.Timer_Queue.Schedule_Results.Is_Ok (Result) then
         Ticker.Last_Timer := Aion.Timer_Queue.Schedule_Results.Value (Result);
         Ticker.Next_Deadline := Aion.Clock.Add (Ticker.Next_Deadline, Ticker.Period);
         Ticker.Tick_Count := Ticker.Tick_Count + 1;
      end if;

      return Result;
   end Tick;

   function Cancel_Last (Ticker : in out Interval)
      return Aion.Timer_Queue.Operation_Results.Result_Type is
   begin
      if not Aion.Timer_Queue.Is_Valid (Ticker.Last_Timer) then
         return Aion.Timer_Queue.Operation_Results.Success (True);
      end if;

      return Aion.Timer_Queue.Cancel (Ticker.Last_Timer);
   end Cancel_Last;

   function Is_Valid (Ticker : Interval) return Boolean is
   begin
      return Ticker.Service /= null and then Ticker.Period > 0;
   end Is_Valid;

   function Period_Of (Ticker : Interval) return Aion.Types.Milliseconds is
   begin
      return Ticker.Period;
   end Period_Of;

   function Next_Deadline_Of (Ticker : Interval) return Aion.Clock.Instant is
   begin
      return Ticker.Next_Deadline;
   end Next_Deadline_Of;

   function Ticks_Of (Ticker : Interval) return Natural is
   begin
      return Ticker.Tick_Count;
   end Ticks_Of;

   function Image (Ticker : Interval) return String is
   begin
      if not Is_Valid (Ticker) then
         return "interval[invalid]";
      end if;

      return
        "interval[name=" & US.To_String (Ticker.Name) &
        ",period_ms=" & Aion.Types.Image (Ticker.Period) &
        ",next=" & Aion.Clock.Image (Ticker.Next_Deadline) &
        ",ticks=" & Trim (Natural'Image (Ticker.Tick_Count)) &
        "]";
   end Image;

end Aion.Interval;
