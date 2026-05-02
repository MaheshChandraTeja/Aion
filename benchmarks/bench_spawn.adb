with Ada.Text_IO;
with Interfaces;
with Aion.Benchmark_Support;
with Aion.Config;
with Aion.Runtime;

procedure Bench_Spawn is
   Timer : Aion.Benchmark_Support.Benchmark_Timer;
   Runtime : constant Aion.Runtime.Runtime_Handle :=
     Aion.Runtime.Create
       (Aion.Config.With_Max_Queue_Depth
          (Aion.Config.With_Workers (Aion.Config.Default, 1), 4_096));
   Snapshot : Aion.Runtime.Runtime_Stats;
   Result : Aion.Benchmark_Support.Benchmark_Result;
begin
   Aion.Benchmark_Support.Start (Timer);
   for I in 1 .. 50_000 loop
      Snapshot := Aion.Runtime.Stats_Of (Runtime);
   end loop;
   Aion.Benchmark_Support.Stop (Timer);
   Result := Aion.Benchmark_Support.Make_Result
     ("spawn_accounting_path", Interfaces.Unsigned_64 (50_000), Timer);
   Ada.Text_IO.Put_Line (Aion.Benchmark_Support.Image (Result));
   Ada.Text_IO.Put_Line ("spawned=" & Interfaces.Unsigned_64'Image (Snapshot.Total_Spawned));
end Bench_Spawn;
