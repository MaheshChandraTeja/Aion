with Test_Support;
with Aion.Tracing;

procedure Test_Tracing is
   use type Aion.Tracing.Span_Id;
   Id : Aion.Tracing.Span_Id;
   Stats : Aion.Tracing.Trace_Stats;
begin
   Test_Support.Section ("tracing");
   Aion.Tracing.Clear;
   Id := Aion.Tracing.Start_Span ("test-span", "test");
   Aion.Tracing.Record_Event ("inside", "test", Id);
   Aion.Tracing.Finish_Span (Id, "test-span", "test");
   Stats := Aion.Tracing.Stats;
   Test_Support.Assert (Stats.Stored = 3, "three trace events should be stored");
   Test_Support.Assert (Aion.Tracing.Event_At (1).Id = Id, "first event should use the span id");
   Test_Support.Assert (Aion.Tracing.Image (Stats)'Length > 0, "trace stats image should be populated");
   Test_Support.Pass ("tracing ring buffer works");
end Test_Tracing;
