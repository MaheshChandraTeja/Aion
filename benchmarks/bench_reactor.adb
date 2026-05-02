with Ada.Text_IO;
with Interfaces;
with Aion.Benchmark_Support;
with Aion.Reactor;

procedure Bench_Reactor is
   Service : Aion.Reactor.Reactor_Service_Access :=
     Aion.Reactor.Create_Service (Max_Resources => 4_096, Max_Events => 4_096);
   Timer : Aion.Benchmark_Support.Benchmark_Timer;
   Result : Aion.Benchmark_Support.Benchmark_Result;
   Stats : Aion.Reactor.Reactor_Stats;
begin
   Aion.Benchmark_Support.Start (Timer);
   for I in 1 .. 100_000 loop
      Stats := Aion.Reactor.Stats_Of (Service.all);
   end loop;
   Aion.Benchmark_Support.Stop (Timer);
   Result := Aion.Benchmark_Support.Make_Result
     ("reactor_stats_snapshot", Interfaces.Unsigned_64 (100_000), Timer);
   Ada.Text_IO.Put_Line (Aion.Benchmark_Support.Image (Result));
   Ada.Text_IO.Put_Line (Aion.Reactor.Image (Stats));
   Aion.Reactor.Destroy (Service);
end Bench_Reactor;
