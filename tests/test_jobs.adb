with Aion.Yield;

package body Test_Jobs is
   use type Interfaces.Unsigned_64;

   protected Counters is
      procedure Reset;
      procedure Inc;
      procedure Inc_Fault;
      function Count return Interfaces.Unsigned_64;
      function Fault_Count return Interfaces.Unsigned_64;
   private
      Total  : Interfaces.Unsigned_64 := 0;
      Faults : Interfaces.Unsigned_64 := 0;
   end Counters;

   protected body Counters is
      procedure Reset is
      begin
         Total := 0;
         Faults := 0;
      end Reset;

      procedure Inc is
      begin
         Total := Total + 1;
      end Inc;

      procedure Inc_Fault is
      begin
         Faults := Faults + 1;
      end Inc_Fault;

      function Count return Interfaces.Unsigned_64 is
      begin
         return Total;
      end Count;

      function Fault_Count return Interfaces.Unsigned_64 is
      begin
         return Faults;
      end Fault_Count;
   end Counters;

   procedure Reset is
   begin
      Counters.Reset;
   end Reset;

   function Count return Interfaces.Unsigned_64 is
   begin
      return Counters.Count;
   end Count;

   function Fault_Count return Interfaces.Unsigned_64 is
   begin
      return Counters.Fault_Count;
   end Fault_Count;

   procedure Increment is
   begin
      Counters.Inc;
   end Increment;

   procedure Yielding_Increment is
   begin
      Aion.Yield.Now;
      Counters.Inc;
   end Yielding_Increment;

   procedure Slow_Increment is
   begin
      delay 0.005;
      Counters.Inc;
   end Slow_Increment;

   procedure Faulting is
   begin
      Counters.Inc_Fault;
      raise Program_Error with "intentional test failure";
   end Faulting;

end Test_Jobs;
