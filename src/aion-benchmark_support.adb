with Ada.Calendar;
with Ada.Strings.Fixed;

package body Aion.Benchmark_Support is
   use type Aion.Types.Milliseconds;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function U64_Image (Value : Interfaces.Unsigned_64) return String is
   begin
      return Trim (Interfaces.Unsigned_64'Image (Value));
   end U64_Image;

   function Ms_Image (Value : Aion.Types.Milliseconds) return String is
   begin
      return Trim (Aion.Types.Milliseconds'Image (Value));
   end Ms_Image;

   function Float_Image (Value : Long_Float) return String is
   begin
      return Trim (Long_Float'Image (Value));
   end Float_Image;

   function Now_Seconds return Duration is
   begin
      return Ada.Calendar.Seconds (Ada.Calendar.Clock);
   end Now_Seconds;

   procedure Store_Name
     (Source : String;
      Target : out String;
      Length : out Natural) is
      Last : constant Natural := Natural'Min (Source'Length, Target'Length);
   begin
      Target := (others => ' ');
      Length := Last;
      if Last > 0 then
         Target (Target'First .. Target'First + Last - 1) :=
           Source (Source'First .. Source'First + Last - 1);
      end if;
   end Store_Name;

   procedure Start (Timer : out Benchmark_Timer) is
   begin
      Timer.Started := True;
      Timer.Stopped := False;
      Timer.Start_Ticks := Now_Seconds;
      Timer.Stop_Ticks := Timer.Start_Ticks;
   end Start;

   procedure Stop (Timer : in out Benchmark_Timer) is
   begin
      Timer.Stop_Ticks := Now_Seconds;
      Timer.Stopped := True;
   end Stop;

   function Elapsed_Milliseconds
     (Timer : Benchmark_Timer) return Aion.Types.Milliseconds is
      End_Ticks : constant Duration :=
        (if Timer.Stopped then Timer.Stop_Ticks else Now_Seconds);
      Elapsed : Duration := End_Ticks - Timer.Start_Ticks;
   begin
      if not Timer.Started then
         return 0;
      end if;

      if Elapsed < 0.0 then
         Elapsed := 0.0;
      end if;

      return Aion.Types.Milliseconds (Long_Long_Integer (Elapsed * 1_000.0));
   end Elapsed_Milliseconds;

   function Throughput_Per_Second
     (Operations : Interfaces.Unsigned_64;
      Elapsed_Ms : Aion.Types.Milliseconds) return Long_Float is
   begin
      if Elapsed_Ms = 0 then
         return Long_Float (Operations);
      end if;

      return Long_Float (Operations) / (Long_Float (Elapsed_Ms) / 1_000.0);
   end Throughput_Per_Second;

   function Make_Result
     (Name       : String;
      Operations : Interfaces.Unsigned_64;
      Timer      : Benchmark_Timer) return Benchmark_Result is
      Result : Benchmark_Result;
      Elapsed : constant Aion.Types.Milliseconds := Elapsed_Milliseconds (Timer);
   begin
      Store_Name (Name, Result.Name, Result.Name_Len);
      Result.Operations := Operations;
      Result.Elapsed_Ms := Elapsed;
      Result.Ops_Per_Sec := Throughput_Per_Second (Operations, Elapsed);
      return Result;
   end Make_Result;

   function Image (Result : Benchmark_Result) return String is
      Name_Last : constant Natural := Natural'Max (1, Result.Name_Len);
   begin
      return Result.Name (1 .. Name_Last) & ": operations=" &
        U64_Image (Result.Operations) & ", elapsed_ms=" &
        Ms_Image (Result.Elapsed_Ms) & ", ops_per_sec=" &
        Float_Image (Result.Ops_Per_Sec);
   end Image;
end Aion.Benchmark_Support;
