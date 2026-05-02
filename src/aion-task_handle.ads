--  Copy-safe task handle returned by Aion.Runtime.Spawn.
--  Handles keep a shared protected state cell so worker tasks, callers, and
--  scheduler-owned job records observe the same task lifecycle.

with Ada.Finalization;
with Ada.Strings.Unbounded;
with Aion.Errors;
with Aion.Types;

package Aion.Task_Handle is

   type Task_Handle is new Ada.Finalization.Controlled with private;

   Null_Handle : constant Task_Handle;

   function Create
     (Id   : Aion.Types.Task_Id;
      Name : String) return Task_Handle;

   function Is_Valid (Handle : Task_Handle) return Boolean;
   function Id_Of (Handle : Task_Handle) return Aion.Types.Task_Id;
   function Name_Of (Handle : Task_Handle) return String;
   function State_Of (Handle : Task_Handle) return Aion.Types.Task_State;
   function Last_Error_Of (Handle : Task_Handle) return Aion.Errors.Error;

   function Is_Done (Handle : Task_Handle) return Boolean;
   function Image (Handle : Task_Handle) return String;

   --  Runtime-internal lifecycle updates. They are intentionally public so
   --  sibling runtime packages can use them without creating a second private
   --  lifecycle model.
   procedure Mark_Scheduled (Handle : in out Task_Handle);
   procedure Mark_Running (Handle : in out Task_Handle);
   procedure Mark_Completed (Handle : in out Task_Handle);
   procedure Mark_Cancelled
     (Handle : in out Task_Handle;
      Reason : String := "task cancelled");
   procedure Mark_Faulted
     (Handle : in out Task_Handle;
      Failure : Aion.Errors.Error);

private
   package US renames Ada.Strings.Unbounded;

   protected type State_Cell is
      procedure Retain;
      procedure Release (Remaining : out Natural);

      procedure Set_State (State : Aion.Types.Task_State);
      procedure Set_Error (Failure : Aion.Errors.Error);

      function State return Aion.Types.Task_State;
      function Last_Error return Aion.Errors.Error;
      function References return Natural;
   private
      Ref_Count : Natural := 1;
      Current_State : Aion.Types.Task_State := Aion.Types.Task_Pending;
      Failure_Info : Aion.Errors.Error := Aion.Errors.Ok;
   end State_Cell;

   type State_Cell_Access is access State_Cell;

   type Task_Handle is new Ada.Finalization.Controlled with record
      Id   : Aion.Types.Task_Id := Aion.Types.No_Task;
      Name : US.Unbounded_String := US.Null_Unbounded_String;
      Cell : State_Cell_Access := null;
   end record;

   overriding procedure Adjust (Handle : in out Task_Handle);
   overriding procedure Finalize (Handle : in out Task_Handle);

   Null_Handle : constant Task_Handle :=
     (Ada.Finalization.Controlled with
      Id   => Aion.Types.No_Task,
      Name => US.Null_Unbounded_String,
      Cell => null);

end Aion.Task_Handle;
