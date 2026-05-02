--  Runtime lifecycle, task spawning, worker management, and runtime stats.
--  This is the central integration point for Module 2 and the dependency all
--  later Aion modules should target instead of building private worker pools.

with Ada.Finalization;
with Interfaces;
with Aion.Config;
with Aion.Result;
with Aion.Reactor;
with Aion.Scheduler;
with Aion.Task_Handle;
with Aion.Task_Id;
with Aion.Timer_Queue;
with Aion.Types;

package Aion.Runtime is

   type Runtime_Handle is limited private;

   type Runtime_Stats is record
      Total_Spawned   : Interfaces.Unsigned_64 := 0;
      Active_Tasks    : Interfaces.Unsigned_64 := 0;
      Running_Tasks   : Interfaces.Unsigned_64 := 0;
      Completed_Tasks : Interfaces.Unsigned_64 := 0;
      Failed_Tasks    : Interfaces.Unsigned_64 := 0;
      Cancelled_Tasks : Interfaces.Unsigned_64 := 0;
      Rejected_Tasks  : Interfaces.Unsigned_64 := 0;
      Queue_Depth     : Natural := 0;
      Queue_Capacity  : Natural := 0;
      Worker_Count    : Natural := 0;
      Running_Workers : Natural := 0;
      Reactor_Resources : Natural := 0;
      Reactor_Event_Depth : Natural := 0;
   end record;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);
   package Spawn_Results is new Aion.Result.Generic_Result
     (Aion.Task_Handle.Task_Handle);

   function Create
     (Config : Aion.Config.Runtime_Config := Aion.Config.Default)
      return Runtime_Handle;

   function Start
     (Runtime : in out Runtime_Handle) return Operation_Results.Result_Type;

   function Spawn
     (Runtime : in out Runtime_Handle;
      Name    : String;
      Work    : Aion.Scheduler.Job_Procedure)
      return Spawn_Results.Result_Type;

   function Shutdown
     (Runtime : in out Runtime_Handle) return Operation_Results.Result_Type;

   function State_Of (Runtime : Runtime_Handle) return Aion.Types.Runtime_State;
   function Config_Of (Runtime : Runtime_Handle) return Aion.Config.Runtime_Config;
   function Stats_Of (Runtime : Runtime_Handle) return Runtime_Stats;
   function Queue_Depth_Of (Runtime : Runtime_Handle) return Natural;
   function Timers_Of
     (Runtime : in out Runtime_Handle) return Aion.Timer_Queue.Timer_Service_Access;
   function Reactor_Of
     (Runtime : in out Runtime_Handle) return Aion.Reactor.Reactor_Service_Access;
   function Is_Running (Runtime : Runtime_Handle) return Boolean;
   function Is_Stopped (Runtime : Runtime_Handle) return Boolean;

   function Image (Stats : Runtime_Stats) return String;

private
   protected type Runtime_State_Cell is
      procedure Set_State (State : Aion.Types.Runtime_State);
      procedure Set_Worker_Target (Count : Natural);

      procedure Mark_Worker_Started;
      procedure Mark_Worker_Stopped;

      procedure Mark_Spawned;
      procedure Mark_Task_Running;
      procedure Mark_Task_Completed;
      procedure Mark_Task_Failed;
      procedure Mark_Tasks_Cancelled (Count : Natural);
      procedure Mark_Spawn_Rejected;

      function State return Aion.Types.Runtime_State;
      function Active_Task_Count return Interfaces.Unsigned_64;
      function Running_Worker_Count return Natural;
      function All_Workers_Stopped return Boolean;
      function Snapshot
        (Queue_Depth         : Natural;
         Queue_Capacity      : Natural;
         Reactor_Resources   : Natural;
         Reactor_Event_Depth : Natural) return Runtime_Stats;
   private
      Current_State : Aion.Types.Runtime_State := Aion.Types.Runtime_Created;

      Spawned_Total   : Interfaces.Unsigned_64 := 0;
      Active_Total    : Interfaces.Unsigned_64 := 0;
      Running_Total   : Interfaces.Unsigned_64 := 0;
      Completed_Total : Interfaces.Unsigned_64 := 0;
      Failed_Total    : Interfaces.Unsigned_64 := 0;
      Cancelled_Total : Interfaces.Unsigned_64 := 0;
      Rejected_Total  : Interfaces.Unsigned_64 := 0;

      Target_Workers  : Natural := 0;
      Started_Workers : Natural := 0;
      Stopped_Workers : Natural := 0;
   end Runtime_State_Cell;

   type Runtime_State_Access is access all Runtime_State_Cell;

   task type Worker_Task
     (Worker_No : Positive;
      Queue     : not null Aion.Scheduler.Job_Queue_Access;
      State     : not null Runtime_State_Access);

   type Worker_Access is access Worker_Task;
   type Worker_Array is array (Positive range <>) of Worker_Access;
   type Worker_Array_Access is access Worker_Array;

   type Runtime_Handle is new Ada.Finalization.Limited_Controlled with record
      Config  : Aion.Config.Runtime_Config := Aion.Config.Default;
      Queue   : Aion.Scheduler.Job_Queue_Access := null;
      State   : Runtime_State_Access := null;
      Ids     : Aion.Task_Id.Generator_Access := null;
      Timers  : Aion.Timer_Queue.Timer_Service_Access := null;
      Reactor : Aion.Reactor.Reactor_Service_Access := null;
      Workers : Worker_Array_Access := null;
   end record;

   overriding procedure Finalize (Runtime : in out Runtime_Handle);

end Aion.Runtime;
