with Ada.Strings.Fixed;

package body Aion.Metrics is
   use type Aion.Reactor.Reactor_Service_Access;
   use type Aion.Timer_Queue.Timer_Service_Access;
   use type Interfaces.Unsigned_64;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function U64_Image (Value : Interfaces.Unsigned_64) return String is
   begin
      return Trim (Interfaces.Unsigned_64'Image (Value));
   end U64_Image;

   function Bool_Image (Value : Boolean) return String is
   begin
      if Value then
         return "true";
      else
         return "false";
      end if;
   end Bool_Image;

   function To_U64 (Value : Natural) return Interfaces.Unsigned_64 is
   begin
      return Interfaces.Unsigned_64 (Value);
   end To_U64;

   function Counters_From
     (Runtime      : Aion.Runtime.Runtime_Stats;
      Timers       : Aion.Timer_Queue.Timer_Stats;
      Reactor      : Aion.Reactor.Reactor_Stats;
      Channel      : Aion.Channel.Channel_Stats;
      Cancellation : Aion.Cancel.Cancellation_Stats) return Metric_Counters is
   begin
      return
        (Created   => Runtime.Total_Spawned +
                      Interfaces.Unsigned_64 (Timers.Scheduled_Total) +
                      Cancellation.Created_Tokens,
         Active    => Runtime.Active_Tasks +
                      Interfaces.Unsigned_64 (Timers.Pending) +
                      Interfaces.Unsigned_64 (Reactor.Registered_Resources) +
                      Interfaces.Unsigned_64 (Channel.Buffered),
         Completed => Runtime.Completed_Tasks +
                      Interfaces.Unsigned_64 (Timers.Fired_Total) +
                      Channel.Received,
         Failed    => Runtime.Failed_Tasks +
                      Runtime.Rejected_Tasks +
                      Interfaces.Unsigned_64 (Timers.Rejected_Total) +
                      Interfaces.Unsigned_64 (Reactor.Readiness_Dropped) +
                      Channel.Failures,
         Cancelled => Runtime.Cancelled_Tasks +
                      Interfaces.Unsigned_64 (Timers.Cancelled_Total) +
                      Cancellation.Cancel_Requests,
         Queued    => To_U64 (Runtime.Queue_Depth) +
                      To_U64 (Timers.Pending) +
                      To_U64 (Reactor.Event_Depth) +
                      To_U64 (Channel.Buffered),
         Capacity  => To_U64 (Runtime.Queue_Capacity) +
                      To_U64 (Timers.Capacity) +
                      To_U64 (Reactor.Event_Capacity) +
                      To_U64 (Channel.Capacity),
         Wakeups   => Interfaces.Unsigned_64 (Reactor.Readiness_Dispatched) +
                      Channel.Wakeups +
                      Interfaces.Unsigned_64 (Timers.Fired_Total) +
                      Cancellation.Awaiters_Released);
   end Counters_From;

   function Normalize (Snapshot : Metrics_Snapshot) return Metrics_Snapshot is
   begin
      return
        (Runtime => Snapshot.Runtime,
         Timers => Snapshot.Timers,
         Reactor => Snapshot.Reactor,
         Channel => Snapshot.Channel,
         Cancellation => Snapshot.Cancellation,
         Totals => Counters_From
           (Snapshot.Runtime,
            Snapshot.Timers,
            Snapshot.Reactor,
            Snapshot.Channel,
            Snapshot.Cancellation));
   end Normalize;

   function From_Runtime
     (Runtime : in out Aion.Runtime.Runtime_Handle)
      return Metrics_Snapshot is
      Runtime_Stats : constant Aion.Runtime.Runtime_Stats :=
        Aion.Runtime.Stats_Of (Runtime);
      Timer_Service : constant Aion.Timer_Queue.Timer_Service_Access :=
        Aion.Runtime.Timers_Of (Runtime);
      Reactor_Service : constant Aion.Reactor.Reactor_Service_Access :=
        Aion.Runtime.Reactor_Of (Runtime);
      Timer_Stats : Aion.Timer_Queue.Timer_Stats := Zero_Timers;
      Reactor_Stats : Aion.Reactor.Reactor_Stats := Zero_Reactor;
   begin
      if Timer_Service /= null then
         Timer_Stats := Aion.Timer_Queue.Stats_Of (Timer_Service.all);
      end if;

      if Reactor_Service /= null then
         Reactor_Stats := Aion.Reactor.Stats_Of (Reactor_Service.all);
      end if;

      return Normalize
        ((Runtime => Runtime_Stats,
          Timers => Timer_Stats,
          Reactor => Reactor_Stats,
          Channel => Zero_Channel,
          Cancellation => Zero_Cancellation,
          Totals => Empty_Counters));
   end From_Runtime;

   function From_Timer_Service
     (Service : Aion.Timer_Queue.Timer_Service)
      return Metrics_Snapshot is
   begin
      return Normalize
        ((Runtime => Zero_Runtime,
          Timers => Aion.Timer_Queue.Stats_Of (Service),
          Reactor => Zero_Reactor,
          Channel => Zero_Channel,
          Cancellation => Zero_Cancellation,
          Totals => Empty_Counters));
   end From_Timer_Service;

   function From_Reactor_Service
     (Service : Aion.Reactor.Reactor_Service)
      return Metrics_Snapshot is
   begin
      return Normalize
        ((Runtime => Zero_Runtime,
          Timers => Zero_Timers,
          Reactor => Aion.Reactor.Stats_Of (Service),
          Channel => Zero_Channel,
          Cancellation => Zero_Cancellation,
          Totals => Empty_Counters));
   end From_Reactor_Service;

   function From_Channel
     (Stats : Aion.Channel.Channel_Stats)
      return Metrics_Snapshot is
   begin
      return Normalize
        ((Runtime => Zero_Runtime,
          Timers => Zero_Timers,
          Reactor => Zero_Reactor,
          Channel => Stats,
          Cancellation => Zero_Cancellation,
          Totals => Empty_Counters));
   end From_Channel;

   function From_Cancellation
     (Stats : Aion.Cancel.Cancellation_Stats)
      return Metrics_Snapshot is
   begin
      return Normalize
        ((Runtime => Zero_Runtime,
          Timers => Zero_Timers,
          Reactor => Zero_Reactor,
          Channel => Zero_Channel,
          Cancellation => Stats,
          Totals => Empty_Counters));
   end From_Cancellation;

   function Combine
     (Left  : Metrics_Snapshot;
      Right : Metrics_Snapshot) return Metrics_Snapshot is
      Combined : Metrics_Snapshot;
   begin
      Combined.Runtime :=
        (Total_Spawned => Left.Runtime.Total_Spawned + Right.Runtime.Total_Spawned,
         Active_Tasks => Left.Runtime.Active_Tasks + Right.Runtime.Active_Tasks,
         Running_Tasks => Left.Runtime.Running_Tasks + Right.Runtime.Running_Tasks,
         Completed_Tasks => Left.Runtime.Completed_Tasks + Right.Runtime.Completed_Tasks,
         Failed_Tasks => Left.Runtime.Failed_Tasks + Right.Runtime.Failed_Tasks,
         Cancelled_Tasks => Left.Runtime.Cancelled_Tasks + Right.Runtime.Cancelled_Tasks,
         Rejected_Tasks => Left.Runtime.Rejected_Tasks + Right.Runtime.Rejected_Tasks,
         Queue_Depth => Left.Runtime.Queue_Depth + Right.Runtime.Queue_Depth,
         Queue_Capacity => Left.Runtime.Queue_Capacity + Right.Runtime.Queue_Capacity,
         Worker_Count => Left.Runtime.Worker_Count + Right.Runtime.Worker_Count,
         Running_Workers => Left.Runtime.Running_Workers + Right.Runtime.Running_Workers,
         Reactor_Resources => Left.Runtime.Reactor_Resources + Right.Runtime.Reactor_Resources,
         Reactor_Event_Depth => Left.Runtime.Reactor_Event_Depth + Right.Runtime.Reactor_Event_Depth);

      Combined.Timers :=
        (Capacity => Left.Timers.Capacity + Right.Timers.Capacity,
         Pending => Left.Timers.Pending + Right.Timers.Pending,
         Scheduled_Total => Left.Timers.Scheduled_Total + Right.Timers.Scheduled_Total,
         Fired_Total => Left.Timers.Fired_Total + Right.Timers.Fired_Total,
         Cancelled_Total => Left.Timers.Cancelled_Total + Right.Timers.Cancelled_Total,
         Rejected_Total => Left.Timers.Rejected_Total + Right.Timers.Rejected_Total,
         Worker_Running => Left.Timers.Worker_Running or else Right.Timers.Worker_Running,
         Stop_Requested => Left.Timers.Stop_Requested or else Right.Timers.Stop_Requested);

      Combined.Reactor :=
        (Backend => Left.Reactor.Backend,
         Max_Resources => Left.Reactor.Max_Resources + Right.Reactor.Max_Resources,
         Registered_Resources => Left.Reactor.Registered_Resources + Right.Reactor.Registered_Resources,
         Event_Depth => Left.Reactor.Event_Depth + Right.Reactor.Event_Depth,
         Event_Capacity => Left.Reactor.Event_Capacity + Right.Reactor.Event_Capacity,
         Registered_Total => Left.Reactor.Registered_Total + Right.Reactor.Registered_Total,
         Unregistered_Total => Left.Reactor.Unregistered_Total + Right.Reactor.Unregistered_Total,
         Interest_Updates => Left.Reactor.Interest_Updates + Right.Reactor.Interest_Updates,
         Readiness_Queued => Left.Reactor.Readiness_Queued + Right.Reactor.Readiness_Queued,
         Readiness_Dispatched => Left.Reactor.Readiness_Dispatched + Right.Reactor.Readiness_Dispatched,
         Readiness_Dropped => Left.Reactor.Readiness_Dropped + Right.Reactor.Readiness_Dropped,
         Worker_Running => Left.Reactor.Worker_Running or else Right.Reactor.Worker_Running,
         Stop_Requested => Left.Reactor.Stop_Requested or else Right.Reactor.Stop_Requested);

      Combined.Channel :=
        (Buffered => Left.Channel.Buffered + Right.Channel.Buffered,
         Capacity => Left.Channel.Capacity + Right.Channel.Capacity,
         Waiting_Senders => Left.Channel.Waiting_Senders + Right.Channel.Waiting_Senders,
         Waiting_Receivers => Left.Channel.Waiting_Receivers + Right.Channel.Waiting_Receivers,
         Sent => Left.Channel.Sent + Right.Channel.Sent,
         Received => Left.Channel.Received + Right.Channel.Received,
         Wakeups => Left.Channel.Wakeups + Right.Channel.Wakeups,
         Dropped => Left.Channel.Dropped + Right.Channel.Dropped,
         Closed => Left.Channel.Closed or else Right.Channel.Closed,
         Failures => Left.Channel.Failures + Right.Channel.Failures);

      Combined.Cancellation :=
        (Created_Tokens => Left.Cancellation.Created_Tokens + Right.Cancellation.Created_Tokens,
         Cancel_Requests => Left.Cancellation.Cancel_Requests + Right.Cancellation.Cancel_Requests,
         Propagated_Requests => Left.Cancellation.Propagated_Requests + Right.Cancellation.Propagated_Requests,
         Awaiters_Released => Left.Cancellation.Awaiters_Released + Right.Cancellation.Awaiters_Released,
         Deadline_Expirations => Left.Cancellation.Deadline_Expirations + Right.Cancellation.Deadline_Expirations);

      return Normalize (Combined);
   end Combine;

   function Totals_Of
     (Snapshot : Metrics_Snapshot) return Metric_Counters is
   begin
      return Snapshot.Totals;
   end Totals_Of;

   function Image (Kind : Component_Kind) return String is
   begin
      case Kind is
         when Component_Runtime => return "runtime";
         when Component_Scheduler => return "scheduler";
         when Component_Timer => return "timer";
         when Component_Reactor => return "reactor";
         when Component_Channel => return "channel";
         when Component_Cancellation => return "cancellation";
         when Component_Custom => return "custom";
      end case;
   end Image;

   function Image (Counters : Metric_Counters) return String is
   begin
      return "Metric_Counters(created=" & U64_Image (Counters.Created) &
        ", active=" & U64_Image (Counters.Active) &
        ", completed=" & U64_Image (Counters.Completed) &
        ", failed=" & U64_Image (Counters.Failed) &
        ", cancelled=" & U64_Image (Counters.Cancelled) &
        ", queued=" & U64_Image (Counters.Queued) &
        ", capacity=" & U64_Image (Counters.Capacity) &
        ", wakeups=" & U64_Image (Counters.Wakeups) & ")";
   end Image;

   function Image (Snapshot : Metrics_Snapshot) return String is
   begin
      return "Metrics_Snapshot(" & Image (Snapshot.Totals) &
        ", timers_running=" & Bool_Image (Snapshot.Timers.Worker_Running) &
        ", reactor_stop=" & Bool_Image (Snapshot.Reactor.Stop_Requested) & ")";
   end Image;
end Aion.Metrics;
