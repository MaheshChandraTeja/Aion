with Ada.Text_IO;
with Aion.Config;
with Aion.Diagnostics;
with Aion.Metrics;
with Aion.Runtime;
with Aion.Tracing;

procedure Observability_Demo is
   Config : constant Aion.Config.Runtime_Config :=
     Aion.Config.With_Tracing
       (Aion.Config.With_Metrics (Aion.Config.Default, True), True);
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create (Config);
   Span : Aion.Tracing.Span_Id;
   Snapshot : Aion.Metrics.Metrics_Snapshot;
begin
   Span := Aion.Tracing.Start_Span ("observability-demo", "example");
   Snapshot := Aion.Metrics.From_Runtime (Runtime);
   Ada.Text_IO.Put_Line (Aion.Metrics.Image (Snapshot));
   Ada.Text_IO.Put_Line (Aion.Diagnostics.Report (Runtime));
   Aion.Tracing.Record_Event ("report-generated", "example", Span);
   Aion.Tracing.Finish_Span (Span, "observability-demo", "example");
   Ada.Text_IO.Put_Line (Aion.Tracing.Image (Aion.Tracing.Stats));
end Observability_Demo;
