with Ada.Text_IO;
with Interfaces;
with Aion.Benchmark_Support;
with Aion.Timer_Queue;
with Aion.Types;

procedure Bench_Timers is
   Service : Aion.Timer_Queue.Timer_Service_Access :=
     Aion.Timer_Queue.Create_Service (Capacity => 16_384);
   Timer : Aion.Benchmark_Support.Benchmark_Timer;
   Result : Aion.Benchmark_Support.Benchmark_Result;
begin
   Aion.Benchmark_Support.Start (Timer);
   for I in 1 .. 10_000 loop
      declare
         Scheduled : constant Aion.Timer_Queue.Schedule_Results.Result_Type :=
           Aion.Timer_Queue.Schedule
             (Service,
              Delay_Ms => Aion.Types.Milliseconds (60_000),
              Name  => "bench.timer");
         pragma Unreferenced (Scheduled);
      begin
         null;
      end;
   end loop;
   Aion.Benchmark_Support.Stop (Timer);
   Result := Aion.Benchmark_Support.Make_Result
     ("timer_schedule", Interfaces.Unsigned_64 (10_000), Timer);
   Ada.Text_IO.Put_Line (Aion.Benchmark_Support.Image (Result));
   Aion.Timer_Queue.Destroy (Service);
end Bench_Timers;
