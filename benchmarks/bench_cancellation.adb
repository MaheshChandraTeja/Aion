with Ada.Text_IO;
with Interfaces;
with Aion.Benchmark_Support;
with Aion.Cancel_Source;

procedure Bench_Cancellation is
   Timer : Aion.Benchmark_Support.Benchmark_Timer;
   Result : Aion.Benchmark_Support.Benchmark_Result;
begin
   Aion.Benchmark_Support.Start (Timer);
   for I in 1 .. 50_000 loop
      declare
         Source : constant Aion.Cancel_Source.Cancel_Source :=
           Aion.Cancel_Source.Create (Name => "bench.cancel");
         Cancel_Result : constant Aion.Cancel_Source.Operation_Results.Result_Type :=
           Aion.Cancel_Source.Cancel (Source, "benchmark cancellation");
         pragma Unreferenced (Cancel_Result);
      begin
         null;
      end;
   end loop;
   Aion.Benchmark_Support.Stop (Timer);
   Result := Aion.Benchmark_Support.Make_Result
     ("cancel_source_create_cancel", Interfaces.Unsigned_64 (50_000), Timer);
   Ada.Text_IO.Put_Line (Aion.Benchmark_Support.Image (Result));
end Bench_Cancellation;
