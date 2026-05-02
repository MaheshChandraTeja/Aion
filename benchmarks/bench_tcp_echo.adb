with Ada.Text_IO;
with Interfaces;
with Aion.Benchmark_Support;
with Aion.Net.Address;

procedure Bench_TCP_Echo is
   Timer : Aion.Benchmark_Support.Benchmark_Timer;
   Result : Aion.Benchmark_Support.Benchmark_Result;
   Address : Aion.Net.Address.Network_Address;
begin
   Aion.Benchmark_Support.Start (Timer);
   for I in 1 .. 100_000 loop
      Address := Aion.Net.Address.Localhost (Port => 9000 + (I mod 100));
   end loop;
   Aion.Benchmark_Support.Stop (Timer);
   Result := Aion.Benchmark_Support.Make_Result
     ("tcp_address_prepare_for_echo", Interfaces.Unsigned_64 (100_000), Timer);
   Ada.Text_IO.Put_Line (Aion.Benchmark_Support.Image (Result));
   Ada.Text_IO.Put_Line (Aion.Net.Address.Image (Address));
end Bench_TCP_Echo;
