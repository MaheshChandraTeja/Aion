with Aion.Errors;

package body Aion.Sleep is
   use type Aion.Timer_Queue.Timer_Service_Access;

   function Sleep_For
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Duration : Aion.Types.Milliseconds;
      Name     : String := "sleep") return Aion.Timer_Queue.Schedule_Results.Result_Type is
      Service : constant Aion.Timer_Queue.Timer_Service_Access :=
        Aion.Runtime.Timers_Of (Runtime);
   begin
      if Service = null then
         return Aion.Timer_Queue.Schedule_Results.Failure
           (Aion.Errors.Invalid_State,
            "runtime does not own a timer service",
            "Aion.Sleep.Sleep_For");
      end if;

      return Aion.Timer_Queue.Schedule (Service, Duration, Name);
   end Sleep_For;

   function Sleep_Until
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Deadline : Aion.Clock.Instant;
      Name     : String := "sleep-until") return Aion.Timer_Queue.Schedule_Results.Result_Type is
      Service : constant Aion.Timer_Queue.Timer_Service_Access :=
        Aion.Runtime.Timers_Of (Runtime);
   begin
      if Service = null then
         return Aion.Timer_Queue.Schedule_Results.Failure
           (Aion.Errors.Invalid_State,
            "runtime does not own a timer service",
            "Aion.Sleep.Sleep_Until");
      end if;

      return Aion.Timer_Queue.Schedule_At (Service, Deadline, Name);
   end Sleep_Until;

   procedure Blocking_Sleep_For (Duration : Aion.Types.Milliseconds) is
   begin
      delay Standard.Duration (Long_Float (Duration) / 1000.0);
   end Blocking_Sleep_For;

   function Wait_For
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Duration : Aion.Types.Milliseconds) return Aion.Timer_Queue.Timer_Futures.Value_Results.Result_Type is
      Scheduled : constant Aion.Timer_Queue.Schedule_Results.Result_Type :=
        Sleep_For (Runtime, Duration, "sleep-wait");
      Timer : Aion.Timer_Queue.Timer_Handle := Aion.Timer_Queue.Null_Timer;
   begin
      if Aion.Timer_Queue.Schedule_Results.Is_Err (Scheduled) then
         return Aion.Timer_Queue.Timer_Futures.Value_Results.Failure
           (Aion.Timer_Queue.Schedule_Results.Error (Scheduled));
      end if;

      Timer := Aion.Timer_Queue.Schedule_Results.Value (Scheduled);
      return Aion.Timer_Queue.Timer_Futures.Await
        (Aion.Timer_Queue.Future_Of (Timer));
   end Wait_For;

end Aion.Sleep;
