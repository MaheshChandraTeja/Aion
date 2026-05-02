--  Reusable benchmark helpers for Aion examples and CI benchmarks.

with Interfaces;
with Aion.Types;

package Aion.Benchmark_Support is
   pragma Elaborate_Body;

   Max_Benchmark_Name_Length : constant Positive := 96;

   type Benchmark_Timer is private;

   type Benchmark_Result is record
      Name       : String (1 .. Max_Benchmark_Name_Length) := (others => ' ');
      Name_Len   : Natural := 0;
      Operations : Interfaces.Unsigned_64 := 0;
      Elapsed_Ms : Aion.Types.Milliseconds := 0;
      Ops_Per_Sec : Long_Float := 0.0;
   end record;

   procedure Start (Timer : out Benchmark_Timer);
   procedure Stop (Timer : in out Benchmark_Timer);

   function Elapsed_Milliseconds
     (Timer : Benchmark_Timer) return Aion.Types.Milliseconds;

   function Make_Result
     (Name       : String;
      Operations : Interfaces.Unsigned_64;
      Timer      : Benchmark_Timer) return Benchmark_Result;

   function Throughput_Per_Second
     (Operations : Interfaces.Unsigned_64;
      Elapsed_Ms : Aion.Types.Milliseconds) return Long_Float;

   function Image (Result : Benchmark_Result) return String;

private
   type Benchmark_Timer is record
      Started : Boolean := False;
      Stopped : Boolean := False;
      Start_Ticks : Duration := 0.0;
      Stop_Ticks  : Duration := 0.0;
   end record;
end Aion.Benchmark_Support;
