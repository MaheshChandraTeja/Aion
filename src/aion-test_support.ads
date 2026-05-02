--  Public test support utilities for Aion users and internal tests.
--
--  This package provides deterministic counters and runtime harnesses without
--  leaking private scheduler details into tests.

with Interfaces;
with Aion.Config;
with Aion.Runtime;
with Aion.Scheduler;

package Aion.Test_Support is
   pragma Elaborate_Body;

   protected type Atomic_Counter is
      procedure Reset;
      procedure Increment;
      procedure Add (Amount : Interfaces.Unsigned_64);
      function Value return Interfaces.Unsigned_64;
   private
      Stored : Interfaces.Unsigned_64 := 0;
   end Atomic_Counter;

   type Runtime_Access is access all Aion.Runtime.Runtime_Handle;

   type Runtime_Harness is limited private;

   procedure Initialize
     (Harness : in out Runtime_Harness;
      Config  : Aion.Config.Runtime_Config := Aion.Config.Default);

   function Runtime_Of
     (Harness : in out Runtime_Harness) return Runtime_Access;

   function Start
     (Harness : in out Runtime_Harness)
      return Aion.Runtime.Operation_Results.Result_Type;

   function Shutdown
     (Harness : in out Runtime_Harness)
      return Aion.Runtime.Operation_Results.Result_Type;

   function Spawn
     (Harness : in out Runtime_Harness;
      Name    : String;
      Work    : Aion.Scheduler.Job_Procedure)
      return Aion.Runtime.Spawn_Results.Result_Type;

   function Spawned_Count
     (Harness : in out Runtime_Harness) return Interfaces.Unsigned_64;

private
   type Runtime_Harness is limited record
      Runtime : Runtime_Access := null;
   end record;
end Aion.Test_Support;
