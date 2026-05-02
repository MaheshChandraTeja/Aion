package body Test_Cancellation_Jobs is
   protected Counters is
      procedure Reset;
      procedure Inc_Quick;
      procedure Inc_Slow;
      procedure Inc_Fault;
      procedure Inc_Coop;
      function Quick return Natural;
      function Slow return Natural;
      function Fault return Natural;
      function Coop return Natural;
   private
      Q : Natural := 0;
      S : Natural := 0;
      F : Natural := 0;
      C : Natural := 0;
   end Counters;

   protected body Counters is
      procedure Reset is
      begin
         Q := 0; S := 0; F := 0; C := 0;
      end Reset;

      procedure Inc_Quick is begin Q := Q + 1; end Inc_Quick;
      procedure Inc_Slow is begin S := S + 1; end Inc_Slow;
      procedure Inc_Fault is begin F := F + 1; end Inc_Fault;
      procedure Inc_Coop is begin C := C + 1; end Inc_Coop;

      function Quick return Natural is begin return Q; end Quick;
      function Slow return Natural is begin return S; end Slow;
      function Fault return Natural is begin return F; end Fault;
      function Coop return Natural is begin return C; end Coop;
   end Counters;

   procedure Reset is
   begin
      Counters.Reset;
   end Reset;

   procedure Quick_Job is
   begin
      Counters.Inc_Quick;
   end Quick_Job;

   procedure Slow_Job is
   begin
      delay 0.010;
      Counters.Inc_Slow;
   end Slow_Job;

   procedure Faulty_Job is
   begin
      Counters.Inc_Fault;
      raise Program_Error with "intentional supervisor test failure";
   end Faulty_Job;

   procedure Cooperative_Job is
   begin
      for I in 1 .. 5 loop
         Counters.Inc_Coop;
         delay 0.001;
      end loop;
   end Cooperative_Job;

   function Quick_Count return Natural is begin return Counters.Quick; end Quick_Count;
   function Slow_Count return Natural is begin return Counters.Slow; end Slow_Count;
   function Fault_Count return Natural is begin return Counters.Fault; end Fault_Count;
   function Cooperative_Count return Natural is begin return Counters.Coop; end Cooperative_Count;
end Test_Cancellation_Jobs;
