--  Aion observability metrics facade.
--
--  This package deliberately collects metrics from existing runtime, timer,
--  reactor, channel, and cancellation stats surfaces. It does not reach into
--  private internals or maintain a second runtime model.

with Interfaces;
with Aion.Cancel;
with Aion.Channel;
with Aion.Platform;
with Aion.Reactor;
with Aion.Runtime;
with Aion.Timer_Queue;

package Aion.Metrics is
   pragma Elaborate_Body;

   type Component_Kind is
     (Component_Runtime,
      Component_Scheduler,
      Component_Timer,
      Component_Reactor,
      Component_Channel,
      Component_Cancellation,
      Component_Custom);

   type Metric_Counters is record
      Created   : Interfaces.Unsigned_64 := 0;
      Active    : Interfaces.Unsigned_64 := 0;
      Completed : Interfaces.Unsigned_64 := 0;
      Failed    : Interfaces.Unsigned_64 := 0;
      Cancelled : Interfaces.Unsigned_64 := 0;
      Queued    : Interfaces.Unsigned_64 := 0;
      Capacity  : Interfaces.Unsigned_64 := 0;
      Wakeups   : Interfaces.Unsigned_64 := 0;
   end record;

   type Metrics_Snapshot is record
      Runtime      : Aion.Runtime.Runtime_Stats;
      Timers       : Aion.Timer_Queue.Timer_Stats;
      Reactor      : Aion.Reactor.Reactor_Stats;
      Channel      : Aion.Channel.Channel_Stats;
      Cancellation : Aion.Cancel.Cancellation_Stats;
      Totals       : Metric_Counters;
   end record;

   Empty_Snapshot : constant Metrics_Snapshot;

   function From_Runtime
     (Runtime : in out Aion.Runtime.Runtime_Handle)
      return Metrics_Snapshot;

   function From_Timer_Service
     (Service : Aion.Timer_Queue.Timer_Service)
      return Metrics_Snapshot;

   function From_Reactor_Service
     (Service : Aion.Reactor.Reactor_Service)
      return Metrics_Snapshot;

   function From_Channel
     (Stats : Aion.Channel.Channel_Stats)
      return Metrics_Snapshot;

   function From_Cancellation
     (Stats : Aion.Cancel.Cancellation_Stats)
      return Metrics_Snapshot;

   function Combine
     (Left  : Metrics_Snapshot;
      Right : Metrics_Snapshot) return Metrics_Snapshot;

   function Totals_Of
     (Snapshot : Metrics_Snapshot) return Metric_Counters;

   function Image (Kind : Component_Kind) return String;
   function Image (Counters : Metric_Counters) return String;
   function Image (Snapshot : Metrics_Snapshot) return String;

private
   Zero_Runtime : constant Aion.Runtime.Runtime_Stats :=
     (Total_Spawned => 0,
      Active_Tasks => 0,
      Running_Tasks => 0,
      Completed_Tasks => 0,
      Failed_Tasks => 0,
      Cancelled_Tasks => 0,
      Rejected_Tasks => 0,
      Queue_Depth => 0,
      Queue_Capacity => 0,
      Worker_Count => 0,
      Running_Workers => 0,
      Reactor_Resources => 0,
      Reactor_Event_Depth => 0);

   Zero_Timers : constant Aion.Timer_Queue.Timer_Stats :=
     (Capacity => 0,
      Pending => 0,
      Scheduled_Total => 0,
      Fired_Total => 0,
      Cancelled_Total => 0,
      Rejected_Total => 0,
      Worker_Running => False,
      Stop_Requested => False);

   Zero_Reactor : constant Aion.Reactor.Reactor_Stats :=
     (Backend => Aion.Platform.Backend_Portable_Select,
      Max_Resources => 0,
      Registered_Resources => 0,
      Event_Depth => 0,
      Event_Capacity => 0,
      Registered_Total => 0,
      Unregistered_Total => 0,
      Interest_Updates => 0,
      Readiness_Queued => 0,
      Readiness_Dispatched => 0,
      Readiness_Dropped => 0,
      Worker_Running => False,
      Stop_Requested => False);

   Zero_Channel : constant Aion.Channel.Channel_Stats :=
     (Buffered => 0,
      Capacity => 0,
      Waiting_Senders => 0,
      Waiting_Receivers => 0,
      Sent => 0,
      Received => 0,
      Wakeups => 0,
      Dropped => 0,
      Closed => False,
      Failures => 0);

   Zero_Cancellation : constant Aion.Cancel.Cancellation_Stats :=
     (Created_Tokens => 0,
      Cancel_Requests => 0,
      Propagated_Requests => 0,
      Awaiters_Released => 0,
      Deadline_Expirations => 0);

   Empty_Counters : constant Metric_Counters :=
     (Created => 0,
      Active => 0,
      Completed => 0,
      Failed => 0,
      Cancelled => 0,
      Queued => 0,
      Capacity => 0,
      Wakeups => 0);

   Empty_Snapshot : constant Metrics_Snapshot :=
     (Runtime => Zero_Runtime,
      Timers => Zero_Timers,
      Reactor => Zero_Reactor,
      Channel => Zero_Channel,
      Cancellation => Zero_Cancellation,
      Totals => Empty_Counters);
end Aion.Metrics;
