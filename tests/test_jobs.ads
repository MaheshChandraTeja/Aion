with Interfaces;

package Test_Jobs is
   procedure Reset;
   function Count return Interfaces.Unsigned_64;
   function Fault_Count return Interfaces.Unsigned_64;

   procedure Increment;
   procedure Yielding_Increment;
   procedure Slow_Increment;
   procedure Faulting;
end Test_Jobs;
