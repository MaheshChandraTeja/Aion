--  Lightweight supervisor for restartable runtime jobs.
--
--  A supervisor records spawned child work, detects faulted handles, and can
--  restart them according to policy. It deliberately uses Aion.Runtime instead
--  of creating a private worker pool.

with Interfaces;
with Aion.Cancel_Source;
with Aion.Cancel_Token;
with Aion.Result;
with Aion.Runtime;
with Aion.Scheduler;
with Aion.Task_Handle;
with Aion.Types;

package Aion.Supervisor is

   type Runtime_Access is access all Aion.Runtime.Runtime_Handle;

   type Supervisor_Policy is
     (Restart_Failed_Children,
      Cancel_All_On_First_Failure,
      Ignore_Failures);

   type Supervisor_Config is record
      Policy           : Supervisor_Policy := Restart_Failed_Children;
      Max_Restarts     : Natural := 3;
      Restart_Delay_Ms : Aion.Types.Milliseconds := 25;
      Join_Timeout_Ms  : Aion.Types.Milliseconds := 0;
   end record;

   type Supervisor_Stats is record
      Children          : Interfaces.Unsigned_64 := 0;
      Active            : Natural := 0;
      Restarts          : Interfaces.Unsigned_64 := 0;
      Failed            : Interfaces.Unsigned_64 := 0;
      Cancelled         : Interfaces.Unsigned_64 := 0;
      Completed         : Interfaces.Unsigned_64 := 0;
      Restart_Rejected  : Interfaces.Unsigned_64 := 0;
   end record;

   type Supervisor (Max_Children : Positive) is limited private;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);

   procedure Initialize
     (Item    : in out Supervisor;
      Runtime : Runtime_Access;
      Name    : String := "supervisor";
      Config  : Supervisor_Config := (others => <>);
      Parent  : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token);

   function Spawn
     (Item : in out Supervisor;
      Name : String;
      Work : Aion.Scheduler.Job_Procedure)
      return Aion.Runtime.Spawn_Results.Result_Type;

   function Tick
     (Item : in out Supervisor) return Operation_Results.Result_Type;

   function Run_Until_Stable
     (Item    : in out Supervisor;
      Timeout : Aion.Types.Milliseconds := 0)
      return Operation_Results.Result_Type;

   function Cancel_All
     (Item   : in out Supervisor;
      Reason : String := "supervisor cancelled")
      return Operation_Results.Result_Type;

   function Token_Of
     (Item : Supervisor) return Aion.Cancel_Token.Cancel_Token;

   function Stats_Of (Item : Supervisor) return Supervisor_Stats;
   function Config_Of (Item : Supervisor) return Supervisor_Config;
   function Image (Stats : Supervisor_Stats) return String;
   function Image (Policy : Supervisor_Policy) return String;

private
   type Child_Record is record
      Used     : Boolean := False;
      Name     : String (1 .. 128) := (others => ' ');
      Name_Len : Natural := 0;
      Work     : Aion.Scheduler.Job_Procedure := null;
      Handle   : Aion.Task_Handle.Task_Handle :=
        Aion.Task_Handle.Null_Handle;
      Restarts : Natural := 0;
   end record;

   type Child_Array is array (Positive range <>) of Child_Record;

   type Supervisor (Max_Children : Positive) is limited record
      Runtime : Runtime_Access := null;
      Source  : Aion.Cancel_Source.Cancel_Source :=
        Aion.Cancel_Source.Null_Source;
      Config  : Supervisor_Config := (others => <>);
      Children : Child_Array (1 .. Max_Children);
   end record;

end Aion.Supervisor;
