with Interfaces;
with Test_Support;
with Aion.Channel;
with Aion.Metrics;

procedure Test_Metrics is
   use type Interfaces.Unsigned_64;
   Channel_Stats : constant Aion.Channel.Channel_Stats :=
     (Buffered => 3,
      Capacity => 8,
      Waiting_Senders => 1,
      Waiting_Receivers => 2,
      Sent => 10,
      Received => 7,
      Wakeups => 4,
      Dropped => 1,
      Closed => False,
      Failures => 0);
   Snapshot : constant Aion.Metrics.Metrics_Snapshot :=
     Aion.Metrics.From_Channel (Channel_Stats);
   Totals : constant Aion.Metrics.Metric_Counters :=
     Aion.Metrics.Totals_Of (Snapshot);
begin
   Test_Support.Section ("metrics");
   Test_Support.Assert (Totals.Active = 3, "channel buffered count contributes to active metrics");
   Test_Support.Assert (Totals.Completed = 7, "channel received count contributes to completed metrics");
   Test_Support.Assert (Totals.Capacity = 8, "channel capacity contributes to capacity metrics");
   Test_Support.Assert (Aion.Metrics.Image (Snapshot)'Length > 0, "metrics image should be populated");
   Test_Support.Pass ("metrics aggregation works");
end Test_Metrics;
