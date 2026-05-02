with Aion.Sync;
with Ada.Text_IO;
with Interfaces;
with Aion.Benchmark_Support;
with Aion.Channel.Bounded;

procedure Bench_Channels is
   package Integer_Channels is
     new Aion.Channel.Bounded.Generic_Bounded_Channel (Integer);

   Channel : Integer_Channels.Bounded_Channel (Capacity => 1_024, Max_Waiters => 1_024);
   Timer : Aion.Benchmark_Support.Benchmark_Timer;
   Result : Aion.Benchmark_Support.Benchmark_Result;
begin
   Aion.Benchmark_Support.Start (Timer);
   for I in 1 .. 100_000 loop
      declare
         Send_Result : constant Aion.Sync.Boolean_Results.Result_Type :=
           Integer_Channels.Try_Send (Channel, I);
         Recv_Result : constant Integer_Channels.Message_Results.Result_Type :=
           Integer_Channels.Try_Receive (Channel);
         pragma Unreferenced (Send_Result, Recv_Result);
      begin
         null;
      end;
   end loop;
   Aion.Benchmark_Support.Stop (Timer);
   Result := Aion.Benchmark_Support.Make_Result
     ("bounded_channel_try_send_receive", Interfaces.Unsigned_64 (100_000), Timer);
   Ada.Text_IO.Put_Line (Aion.Benchmark_Support.Image (Result));
end Bench_Channels;
