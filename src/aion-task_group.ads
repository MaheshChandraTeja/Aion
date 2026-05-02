--  Structured task group built on Aion.Runtime and Aion.Join_Set.

with Interfaces;
with Aion.Cancel;
with Aion.Cancel_Source;
with Aion.Cancel_Token;
with Aion.Join_Set;
with Aion.Result;
with Aion.Runtime;
with Aion.Scheduler;
with Aion.Types;

package Aion.Task_Group is

   type Runtime_Access is access all Aion.Runtime.Runtime_Handle;

   type Task_Group_Stats is record
      Spawned   : Interfaces.Unsigned_64 := 0;
      Completed : Interfaces.Unsigned_64 := 0;
      Failed    : Interfaces.Unsigned_64 := 0;
      Cancelled : Interfaces.Unsigned_64 := 0;
      Pending   : Natural := 0;
   end record;

   type Task_Group (Max_Tasks : Positive) is limited private;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);

   procedure Initialize
     (Group  : in out Task_Group;
      Runtime : Runtime_Access;
      Name    : String := "task-group";
      Parent  : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Policy  : Aion.Cancel.Failure_Policy :=
        Aion.Cancel.Cancel_Siblings_On_Failure);

   function Spawn
     (Group : in out Task_Group;
      Name  : String;
      Work  : Aion.Scheduler.Job_Procedure)
      return Aion.Runtime.Spawn_Results.Result_Type;

   function Join_All
     (Group   : in out Task_Group;
      Timeout : Aion.Types.Milliseconds := 0)
      return Operation_Results.Result_Type;

   function Cancel
     (Group  : in out Task_Group;
      Reason : String := "task group cancelled")
      return Operation_Results.Result_Type;

   function Token_Of
     (Group : Task_Group) return Aion.Cancel_Token.Cancel_Token;

   function Stats_Of (Group : Task_Group) return Task_Group_Stats;
   function Count_Of (Group : Task_Group) return Natural;
   function Pending_Of (Group : Task_Group) return Natural;
   function Is_Cancelled (Group : Task_Group) return Boolean;

   function Image (Stats : Task_Group_Stats) return String;

private
   type Task_Group (Max_Tasks : Positive) is limited record
      Runtime : Runtime_Access := null;
      Source  : Aion.Cancel_Source.Cancel_Source :=
        Aion.Cancel_Source.Null_Source;
      Policy  : Aion.Cancel.Failure_Policy :=
        Aion.Cancel.Cancel_Siblings_On_Failure;
      Set     : Aion.Join_Set.Join_Set (Max_Tasks);
      Name    : String (1 .. 128) := (others => ' ');
      Name_Len : Natural := 0;
   end record;

end Aion.Task_Group;
