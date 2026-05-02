with Ada.Calendar;
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Unchecked_Deallocation;
with Aion.Errors;
with Aion.Shutdown;

package body Aion.Runtime is
   use type Ada.Calendar.Time;
   use type Aion.Reactor.Reactor_Service_Access;
   use type Aion.Scheduler.Job_Procedure;
   use type Aion.Scheduler.Job_Queue_Access;
   use type Aion.Task_Id.Generator_Access;
   use type Aion.Timer_Queue.Timer_Service_Access;
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Milliseconds;
   use type Aion.Types.Runtime_State;

   procedure Free_Queue is new Ada.Unchecked_Deallocation
     (Aion.Scheduler.Job_Queue, Aion.Scheduler.Job_Queue_Access);
   procedure Free_State is new Ada.Unchecked_Deallocation
     (Runtime_State_Cell, Runtime_State_Access);
   procedure Free_Ids is new Ada.Unchecked_Deallocation
     (Aion.Task_Id.Generator, Aion.Task_Id.Generator_Access);
   procedure Free_Worker is new Ada.Unchecked_Deallocation
     (Worker_Task, Worker_Access);
   procedure Free_Worker_Array is new Ada.Unchecked_Deallocation
     (Worker_Array, Worker_Array_Access);

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function U64_Image (Value : Interfaces.Unsigned_64) return String is
   begin
      return Trim (Interfaces.Unsigned_64'Image (Value));
   end U64_Image;

   function Natural_Image (Value : Natural) return String is
   begin
      return Trim (Natural'Image (Value));
   end Natural_Image;

   function Queue_Capacity_For
     (Config : Aion.Config.Runtime_Config) return Positive is
      Requested : constant Natural := Aion.Config.Max_Queue_Depth_Of (Config);
   begin
      if Requested = 0 then
         return 1;
      else
         return Positive (Requested);
      end if;
   end Queue_Capacity_For;

   function To_Duration
     (Milliseconds : Aion.Types.Milliseconds) return Duration is
   begin
      if Milliseconds = 0 then
         return 0.0;
      elsif Milliseconds > Aion.Types.Milliseconds (Natural'Last) then
         return Duration (Natural'Last) / 1000.0;
      else
         return Duration (Natural (Milliseconds)) / 1000.0;
      end if;
   end To_Duration;

   protected body Runtime_State_Cell is
      procedure Set_State (State : Aion.Types.Runtime_State) is
      begin
         Current_State := State;
      end Set_State;

      procedure Set_Worker_Target (Count : Natural) is
      begin
         Target_Workers := Count;
         Started_Workers := 0;
         Stopped_Workers := 0;
      end Set_Worker_Target;

      procedure Mark_Worker_Started is
      begin
         Started_Workers := Started_Workers + 1;
      end Mark_Worker_Started;

      procedure Mark_Worker_Stopped is
      begin
         if Stopped_Workers < Natural'Last then
            Stopped_Workers := Stopped_Workers + 1;
         end if;
      end Mark_Worker_Stopped;

      procedure Mark_Spawned is
      begin
         Spawned_Total := Spawned_Total + 1;
         Active_Total := Active_Total + 1;
      end Mark_Spawned;

      procedure Mark_Task_Running is
      begin
         Running_Total := Running_Total + 1;
      end Mark_Task_Running;

      procedure Mark_Task_Completed is
      begin
         Completed_Total := Completed_Total + 1;

         if Active_Total > 0 then
            Active_Total := Active_Total - 1;
         end if;

         if Running_Total > 0 then
            Running_Total := Running_Total - 1;
         end if;
      end Mark_Task_Completed;

      procedure Mark_Task_Failed is
      begin
         Failed_Total := Failed_Total + 1;

         if Active_Total > 0 then
            Active_Total := Active_Total - 1;
         end if;

         if Running_Total > 0 then
            Running_Total := Running_Total - 1;
         end if;
      end Mark_Task_Failed;

      procedure Mark_Tasks_Cancelled (Count : Natural) is
         Amount : constant Interfaces.Unsigned_64 := Interfaces.Unsigned_64 (Count);
      begin
         Cancelled_Total := Cancelled_Total + Amount;

         if Active_Total >= Amount then
            Active_Total := Active_Total - Amount;
         else
            Active_Total := 0;
         end if;
      end Mark_Tasks_Cancelled;

      procedure Mark_Rejected is
      begin
         Rejected_Total := Rejected_Total + 1;
      end Mark_Rejected;

      function State return Aion.Types.Runtime_State is
      begin
         return Current_State;
      end State;

      function Active_Task_Count return Interfaces.Unsigned_64 is
      begin
         return Active_Total;
      end Active_Task_Count;

      function Running_Worker_Count return Natural is
      begin
         if Started_Workers >= Stopped_Workers then
            return Started_Workers - Stopped_Workers;
         else
            return 0;
         end if;
      end Running_Worker_Count;

      function All_Workers_Stopped return Boolean is
      begin
         return Target_Workers = 0 or else Stopped_Workers >= Target_Workers;
      end All_Workers_Stopped;

      function Snapshot
        (Queue_Depth         : Natural;
         Queue_Capacity      : Natural;
         Reactor_Resources   : Natural;
         Reactor_Event_Depth : Natural) return Runtime_Stats is
      begin
         return Runtime_Stats'
           (Total_Spawned   => Spawned_Total,
            Active_Tasks    => Active_Total,
            Running_Tasks   => Running_Total,
            Completed_Tasks => Completed_Total,
            Failed_Tasks    => Failed_Total,
            Cancelled_Tasks => Cancelled_Total,
            Rejected_Tasks  => Rejected_Total,
            Queue_Depth     => Queue_Depth,
            Queue_Capacity  => Queue_Capacity,
            Worker_Count    => Target_Workers,
            Running_Workers => Running_Worker_Count,
            Reactor_Resources => Reactor_Resources,
            Reactor_Event_Depth => Reactor_Event_Depth);
      end Snapshot;
   end Runtime_State_Cell;

   task body Worker_Task is
      pragma Unreferenced (Worker_No);
      Item   : Aion.Scheduler.Job_Item := Aion.Scheduler.Null_Job;
      Found  : Boolean := False;
      Handle : Aion.Task_Handle.Task_Handle := Aion.Task_Handle.Null_Handle;
      Work   : Aion.Scheduler.Job_Procedure := null;
   begin
      State.Mark_Worker_Started;

      loop
         Queue.Take (Item, Found);
         exit when not Found;

         Handle := Aion.Scheduler.Handle_Of (Item);
         Work := Aion.Scheduler.Work_Of (Item);

         Aion.Task_Handle.Mark_Running (Handle);
         State.Mark_Task_Running;

         begin
            Work.all;
            Aion.Task_Handle.Mark_Completed (Handle);
            State.Mark_Task_Completed;
         exception
            when Failure : others =>
               Aion.Task_Handle.Mark_Faulted
                 (Handle,
                  Aion.Errors.Make
                    (Aion.Errors.Runtime_Error,
                     Ada.Exceptions.Exception_Name (Failure) & ": " &
                       Ada.Exceptions.Exception_Message (Failure),
                     "Aion.Runtime.Worker_Task"));
               State.Mark_Task_Failed;
         end;
      end loop;

      State.Mark_Worker_Stopped;
   exception
      when Fatal : others =>
         State.Set_State (Aion.Types.Runtime_Failed);
         State.Mark_Worker_Stopped;
         pragma Unreferenced (Fatal);
   end Worker_Task;

   function Create
     (Config : Aion.Config.Runtime_Config := Aion.Config.Default)
       return Runtime_Handle is
      Capacity : constant Positive := Queue_Capacity_For (Config);
   begin
      return Runtime : Runtime_Handle do
         Runtime.Config := Config;
         Runtime.Queue := new Aion.Scheduler.Job_Queue (Capacity);
         Runtime.State := new Runtime_State_Cell;
         Runtime.Ids := new Aion.Task_Id.Generator;
         Runtime.Timers := Aion.Timer_Queue.Create_Service (Capacity);
         Runtime.Reactor := Aion.Reactor.Create_Service
           (Max_Resources => Capacity,
            Max_Events    => Capacity);
         Runtime.State.Set_State (Aion.Types.Runtime_Created);
      end return;
   end Create;

   function Start
     (Runtime : in out Runtime_Handle) return Operation_Results.Result_Type is
      Validation : constant Aion.Config.Validation_Results.Result_Type :=
        Aion.Config.Validate (Runtime.Config);
      Worker_Count : constant Positive :=
        Positive (Aion.Config.Effective_Workers_Of (Runtime.Config));
   begin
      if Runtime.Queue = null or else Runtime.State = null or else Runtime.Ids = null then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "runtime was not initialized; use Aion.Runtime.Create or Aion.Runtime.Builder.Build",
            "Aion.Runtime.Start");
      end if;

      if Aion.Config.Validation_Results.Is_Err (Validation) then
         return Operation_Results.Failure (Aion.Config.Validation_Results.Error (Validation));
      end if;

      case Runtime.State.State is
         when Aion.Types.Runtime_Created =>
            null;
         when Aion.Types.Runtime_Running =>
            return Operation_Results.Success (True);
         when others =>
            return Operation_Results.Failure
              (Aion.Errors.Invalid_State,
               "runtime can only be started from the created state",
               "Aion.Runtime.Start");
      end case;

      Runtime.State.Set_State (Aion.Types.Runtime_Initializing);

      if Runtime.Reactor /= null then
         declare
            Reactor_Start : constant Aion.Reactor.Operation_Results.Result_Type :=
              Aion.Reactor.Start (Runtime.Reactor);
         begin
            if Aion.Reactor.Operation_Results.Is_Err (Reactor_Start) then
               Runtime.State.Set_State (Aion.Types.Runtime_Failed);
               return Operation_Results.Failure
                 (Aion.Reactor.Operation_Results.Error (Reactor_Start));
            end if;
         end;
      end if;

      Runtime.State.Set_Worker_Target (Worker_Count);
      Runtime.Workers := new Worker_Array (1 .. Worker_Count);

      Runtime.State.Set_State (Aion.Types.Runtime_Running);

      for Index in Runtime.Workers'Range loop
         Runtime.Workers (Index) := new Worker_Task
           (Worker_No => Index,
            Queue     => Runtime.Queue,
            State     => Runtime.State);
      end loop;

      return Operation_Results.Success (True);
   exception
      when Failure : others =>
         if Runtime.State /= null then
            Runtime.State.Set_State (Aion.Types.Runtime_Failed);
         end if;

         return Operation_Results.Failure
           (Aion.Errors.Runtime_Error,
            Ada.Exceptions.Exception_Name (Failure) & ": " &
              Ada.Exceptions.Exception_Message (Failure),
            "Aion.Runtime.Start");
   end Start;

   function Spawn
     (Runtime : in out Runtime_Handle;
      Name    : String;
      Work    : Aion.Scheduler.Job_Procedure)
      return Spawn_Results.Result_Type is
      Id       : Aion.Types.Task_Id := Aion.Types.No_Task;
      Accepted : Boolean := False;
      Handle   : Aion.Task_Handle.Task_Handle;
      Job      : Aion.Scheduler.Job_Item;
      State    : Aion.Types.Runtime_State := Aion.Types.Runtime_Failed;
   begin
      if Runtime.Queue = null or else Runtime.State = null or else Runtime.Ids = null then
         return Spawn_Results.Failure
           (Aion.Errors.Invalid_State,
            "runtime was not initialized",
            "Aion.Runtime.Spawn");
      end if;

      if Work = null then
         return Spawn_Results.Failure
           (Aion.Errors.Invalid_Argument,
            "spawn requires a non-null job procedure",
            "Aion.Runtime.Spawn");
      end if;

      State := Runtime.State.State;
      if State not in Aion.Types.Runtime_Created | Aion.Types.Runtime_Running then
         return Spawn_Results.Failure
           (Aion.Errors.Invalid_State,
            "tasks can only be spawned while runtime is created or running",
            "Aion.Runtime.Spawn");
      end if;

      Runtime.Ids.Next (Id);
      Handle := Aion.Task_Handle.Create (Id, Name);
      Aion.Task_Handle.Mark_Scheduled (Handle);
      Job := Aion.Scheduler.Make_Job (Handle, Work);

      Runtime.Queue.Try_Enqueue (Job, Accepted);

      if not Accepted then
         Runtime.State.Mark_Rejected;
         Aion.Task_Handle.Mark_Cancelled (Handle, "runtime queue rejected the task");
         return Spawn_Results.Failure
           (Aion.Errors.Capacity_Exceeded,
            "runtime scheduler queue is full or stopping",
            "Aion.Runtime.Spawn");
      end if;

      Runtime.State.Mark_Spawned;
      return Spawn_Results.Success (Handle);
   end Spawn;

   function Shutdown
     (Runtime : in out Runtime_Handle) return Operation_Results.Result_Type is
      Request       : constant Aion.Shutdown.Shutdown_Request :=
        Aion.Shutdown.From_Config (Runtime.Config);
      Timeout       : constant Duration := To_Duration (Aion.Shutdown.Timeout_Of (Request));
      Started_At    : constant Ada.Calendar.Time := Ada.Calendar.Clock;
      Dropped       : Natural := 0;
      Deadline_Hit  : Boolean := False;

      function Timed_Out return Boolean is
      begin
         return Timeout = 0.0 or else Ada.Calendar.Clock - Started_At >= Timeout;
      end Timed_Out;
   begin
      if Runtime.State = null or else Runtime.Queue = null then
         return Operation_Results.Success (True);
      end if;

      if Runtime.State.State = Aion.Types.Runtime_Stopped then
         return Operation_Results.Success (True);
      end if;

      if Runtime.State.State = Aion.Types.Runtime_Failed then
         Runtime.Queue.Request_Stop_Now (Dropped);
         Runtime.State.Mark_Tasks_Cancelled (Dropped);
         if Runtime.Timers /= null then
            Aion.Timer_Queue.Stop (Runtime.Timers.all);
         end if;

         if Runtime.Reactor /= null then
            Aion.Reactor.Stop (Runtime.Reactor.all);
         end if;
      else
         Runtime.State.Set_State (Aion.Types.Runtime_Stopping);

         if Aion.Shutdown.Is_Immediate (Request) then
            Runtime.Queue.Request_Stop_Now (Dropped);
            Runtime.State.Mark_Tasks_Cancelled (Dropped);
            if Runtime.Timers /= null then
               Aion.Timer_Queue.Stop (Runtime.Timers.all);
            end if;
         else
            while Runtime.Queue.Depth > 0 or else Runtime.State.Active_Task_Count > 0 loop
               if Timed_Out then
                  Deadline_Hit := True;
                  exit;
               end if;

               delay 0.001;
            end loop;

            Runtime.Queue.Request_Stop;
         end if;
      end if;

      while not Runtime.State.All_Workers_Stopped loop
         if Timed_Out then
            Deadline_Hit := True;
            exit;
         end if;

         delay 0.001;
      end loop;

      if Deadline_Hit then
         Runtime.State.Set_State (Aion.Types.Runtime_Failed);
         return Operation_Results.Failure
           (Aion.Errors.Timeout,
            "runtime shutdown did not complete before timeout",
            "Aion.Runtime.Shutdown");
      end if;

      if Runtime.Timers /= null then
         Aion.Timer_Queue.Stop (Runtime.Timers.all);
      end if;

      if Runtime.Reactor /= null then
         Aion.Reactor.Stop (Runtime.Reactor.all);
      end if;

      Runtime.State.Set_State (Aion.Types.Runtime_Stopped);
      return Operation_Results.Success (True);
   exception
      when Failure : others =>
         if Runtime.State /= null then
            Runtime.State.Set_State (Aion.Types.Runtime_Failed);
         end if;

         return Operation_Results.Failure
           (Aion.Errors.Runtime_Error,
            Ada.Exceptions.Exception_Name (Failure) & ": " &
              Ada.Exceptions.Exception_Message (Failure),
            "Aion.Runtime.Shutdown");
   end Shutdown;

   function State_Of (Runtime : Runtime_Handle) return Aion.Types.Runtime_State is
   begin
      if Runtime.State = null then
         return Aion.Types.Runtime_Stopped;
      end if;

      return Runtime.State.State;
   end State_Of;

   function Config_Of (Runtime : Runtime_Handle) return Aion.Config.Runtime_Config is
   begin
      return Runtime.Config;
   end Config_Of;

   function Stats_Of (Runtime : Runtime_Handle) return Runtime_Stats is
      Depth    : Natural := 0;
      Capacity : Natural := 0;
      Reactor_Resources : Natural := 0;
      Reactor_Event_Depth : Natural := 0;
   begin
      if Runtime.State = null then
         return Runtime_Stats'(others => <>);
      end if;

      if Runtime.Queue /= null then
         Depth := Runtime.Queue.Depth;
         Capacity := Runtime.Queue.Capacity;
      end if;

      if Runtime.Reactor /= null then
         Reactor_Resources := Aion.Reactor.Resource_Count_Of (Runtime.Reactor.all);
         Reactor_Event_Depth := Aion.Reactor.Event_Depth_Of (Runtime.Reactor.all);
      end if;

      return Runtime.State.Snapshot
        (Queue_Depth         => Depth,
         Queue_Capacity      => Capacity,
         Reactor_Resources   => Reactor_Resources,
         Reactor_Event_Depth => Reactor_Event_Depth);
   end Stats_Of;

   function Queue_Depth_Of (Runtime : Runtime_Handle) return Natural is
   begin
      if Runtime.Queue = null then
         return 0;
      end if;

      return Runtime.Queue.Depth;
   end Queue_Depth_Of;

   function Timers_Of
     (Runtime : in out Runtime_Handle) return Aion.Timer_Queue.Timer_Service_Access is
   begin
      return Runtime.Timers;
   end Timers_Of;

   function Reactor_Of
     (Runtime : in out Runtime_Handle) return Aion.Reactor.Reactor_Service_Access is
   begin
      return Runtime.Reactor;
   end Reactor_Of;

   function Is_Running (Runtime : Runtime_Handle) return Boolean is
   begin
      return State_Of (Runtime) = Aion.Types.Runtime_Running;
   end Is_Running;

   function Is_Stopped (Runtime : Runtime_Handle) return Boolean is
   begin
      return State_Of (Runtime) = Aion.Types.Runtime_Stopped;
   end Is_Stopped;

   function Image (Stats : Runtime_Stats) return String is
   begin
      return
        "Runtime_Stats(spawned=" & U64_Image (Stats.Total_Spawned) &
        ", active=" & U64_Image (Stats.Active_Tasks) &
        ", running=" & U64_Image (Stats.Running_Tasks) &
        ", completed=" & U64_Image (Stats.Completed_Tasks) &
        ", failed=" & U64_Image (Stats.Failed_Tasks) &
        ", cancelled=" & U64_Image (Stats.Cancelled_Tasks) &
        ", rejected=" & U64_Image (Stats.Rejected_Tasks) &
        ", queue_depth=" & Natural_Image (Stats.Queue_Depth) &
        ", queue_capacity=" & Natural_Image (Stats.Queue_Capacity) &
        ", workers=" & Natural_Image (Stats.Worker_Count) &
        ", running_workers=" & Natural_Image (Stats.Running_Workers) &
        ", reactor_resources=" & Natural_Image (Stats.Reactor_Resources) &
        ", reactor_event_depth=" & Natural_Image (Stats.Reactor_Event_Depth) &
        ")";
   end Image;

   overriding procedure Finalize (Runtime : in out Runtime_Handle) is
      Ignored : Operation_Results.Result_Type := Shutdown (Runtime);
      pragma Unreferenced (Ignored);
      Safe_To_Free : constant Boolean :=
        Runtime.State = null or else Runtime.State.All_Workers_Stopped;
   begin
      --  If shutdown timed out, worker tasks may still hold Queue/State access
      --  discriminants. In that rare case we intentionally leak the runtime
      --  internals instead of freeing memory still reachable by live tasks.
      --  Memory leaks are embarrassing; use-after-free is how software becomes
      --  a haunted appliance.
      if not Safe_To_Free then
         return;
      end if;

      if Runtime.Reactor /= null then
         Aion.Reactor.Destroy (Runtime.Reactor);
      end if;

      if Runtime.Timers /= null then
         Aion.Timer_Queue.Destroy (Runtime.Timers);
      end if;

      if Runtime.Workers /= null then
         for Index in Runtime.Workers'Range loop
            if Runtime.Workers (Index) /= null then
               Free_Worker (Runtime.Workers (Index));
            end if;
         end loop;

         Free_Worker_Array (Runtime.Workers);
      end if;

      if Runtime.Queue /= null then
         Free_Queue (Runtime.Queue);
      end if;

      if Runtime.Ids /= null then
         Free_Ids (Runtime.Ids);
      end if;

      if Runtime.State /= null then
         Free_State (Runtime.State);
      end if;
   end Finalize;

end Aion.Runtime;
