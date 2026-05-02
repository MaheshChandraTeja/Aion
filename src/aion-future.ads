--  Generic, typed Future handle for Aion.
--
--  Futures are copy-safe handles over a shared protected state cell. A Promise
--  completes that state exactly once; Await waits on the protected entry rather
--  than spinning. Later modules should reuse this package for async task values,
--  timers, channels, networking, and cancellation results.

with Ada.Finalization;
with Ada.Strings.Unbounded;
with Aion.Completion;
with Aion.Errors;
with Aion.Result;
with Aion.Task_Handle;
with Aion.Types;
with Aion.Waker;

package Aion.Future is

   generic
      type Value_Type is private;
   package Generic_Future is
      subtype Item_Type is Value_Type;

      type Future_Handle is new Ada.Finalization.Controlled with private;

      Null_Future : constant Future_Handle;

      package Value_Results is new Aion.Result.Generic_Result (Value_Type);
      package Operation_Results is new Aion.Result.Generic_Result (Boolean);

      type Future_Snapshot is record
         Id          : Aion.Types.Task_Id := Aion.Types.No_Task;
         State       : Aion.Completion.Completion_State :=
           Aion.Completion.Completion_Pending;
         Source_Task : Aion.Task_Handle.Task_Handle :=
           Aion.Task_Handle.Null_Handle;
         Wake_Count  : Natural := 0;
      end record;

      function Create
        (Name        : String := "";
         Source_Task : Aion.Task_Handle.Task_Handle :=
           Aion.Task_Handle.Null_Handle) return Future_Handle;

      function Is_Valid (Future : Future_Handle) return Boolean;
      function Id_Of (Future : Future_Handle) return Aion.Types.Task_Id;
      function Name_Of (Future : Future_Handle) return String;
      function State_Of
        (Future : Future_Handle) return Aion.Completion.Completion_State;
      function Source_Task_Of
        (Future : Future_Handle) return Aion.Task_Handle.Task_Handle;
      function Snapshot_Of (Future : Future_Handle) return Future_Snapshot;

      function Is_Pending (Future : Future_Handle) return Boolean;
      function Is_Ready (Future : Future_Handle) return Boolean;
      function Is_Done (Future : Future_Handle) return Boolean;
      function Is_Failed (Future : Future_Handle) return Boolean;

      --  Non-blocking read. Pending futures return Invalid_State.
      function Try_Value (Future : Future_Handle) return Value_Results.Result_Type;

      --  Waits until the future reaches a terminal state. This uses a protected
      --  entry and does not busy-spin.
      function Await (Future : Future_Handle) return Value_Results.Result_Type;

      --  Waits up to Timeout. The future is not completed as timed-out by this
      --  operation; the caller simply receives a Timeout result.
      function Await_Timeout
        (Future  : Future_Handle;
         Timeout : Aion.Types.Milliseconds) return Value_Results.Result_Type;

      function Error_Of (Future : Future_Handle) return Aion.Errors.Error;

      --  Attaches a scheduler-facing waker. If the future is already terminal,
      --  the waker is invoked immediately.
      function Attach_Waker
        (Future : Future_Handle;
         Waker  : Aion.Waker.Waker) return Operation_Results.Result_Type;

      function Image (Future : Future_Handle) return String;
      function Image (Snapshot : Future_Snapshot) return String;

      --  Runtime/promise-facing completion hooks. Public by design so sibling
      --  packages can reuse one state model instead of inventing private ones.
      function Complete_Success
        (Future : Future_Handle;
         Value  : Value_Type) return Operation_Results.Result_Type;

      function Complete_Failure
        (Future  : Future_Handle;
         Failure : Aion.Errors.Error) return Operation_Results.Result_Type;

      function Complete_Failure
        (Future  : Future_Handle;
         Code    : Aion.Errors.Error_Code;
         Message : String;
         Origin  : String := "") return Operation_Results.Result_Type;

      function Complete_Cancelled
        (Future : Future_Handle;
         Reason : String := "future cancelled") return Operation_Results.Result_Type;

      function Complete_Timed_Out
        (Future : Future_Handle;
         Reason : String := "future timed out") return Operation_Results.Result_Type;

   private
      package US renames Ada.Strings.Unbounded;

      protected type State_Cell is
         procedure Retain;
         procedure Release (Remaining : out Natural);

         procedure Attach_Waker (Item : Aion.Waker.Waker);

         procedure Complete_Success
           (Value    : in Value_Type;
            Accepted : out Boolean);

         procedure Complete_Error
           (State    : in Aion.Completion.Completion_State;
            Failure  : in Aion.Errors.Error;
            Accepted : out Boolean);

         entry Wait_Until_Done;

         function State return Aion.Completion.Completion_State;
         function Stored return Value_Type;
         function Failure return Aion.Errors.Error;
         function References return Natural;
         function Wake_Count return Natural;
      private
         Ref_Count : Natural := 1;
         Current_State : Aion.Completion.Completion_State :=
           Aion.Completion.Completion_Pending;
         Stored_Value : Value_Type;
         Failure_Info : Aion.Errors.Error := Aion.Errors.Ok;
         Registered_Waker : Aion.Waker.Waker := Aion.Waker.Noop;
         Wake_Total : Natural := 0;
      end State_Cell;

      type State_Cell_Access is access State_Cell;

      type Future_Handle is new Ada.Finalization.Controlled with record
         Id          : Aion.Types.Task_Id := Aion.Types.No_Task;
         Name        : US.Unbounded_String := US.Null_Unbounded_String;
         Source_Task : Aion.Task_Handle.Task_Handle :=
           Aion.Task_Handle.Null_Handle;
         Cell        : State_Cell_Access := null;
      end record;

      overriding procedure Adjust (Future : in out Future_Handle);
      overriding procedure Finalize (Future : in out Future_Handle);

      Null_Future : constant Future_Handle :=
        (Ada.Finalization.Controlled with
         Id          => Aion.Types.No_Task,
         Name        => US.Null_Unbounded_String,
         Source_Task => Aion.Task_Handle.Null_Handle,
         Cell        => null);

   end Generic_Future;

end Aion.Future;
