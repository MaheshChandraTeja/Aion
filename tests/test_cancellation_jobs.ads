package Test_Cancellation_Jobs is
   procedure Reset;
   procedure Quick_Job;
   procedure Slow_Job;
   procedure Faulty_Job;
   procedure Cooperative_Job;

   function Quick_Count return Natural;
   function Slow_Count return Natural;
   function Fault_Count return Natural;
   function Cooperative_Count return Natural;
end Test_Cancellation_Jobs;
