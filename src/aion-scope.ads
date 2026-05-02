--  Lexically-scoped task manager. Use this when a component owns child tasks
--  and wants deterministic cancellation/join behavior at the boundary.

with Aion.Cancel;
with Aion.Cancel_Token;
with Aion.Result;
with Aion.Runtime;
with Aion.Scheduler;
with Aion.Task_Group;
with Aion.Types;

package Aion.Scope is

   type Scope_Handle (Max_Tasks : Positive) is limited private;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);

   procedure Open
     (Scope   : in out Scope_Handle;
      Runtime : Aion.Task_Group.Runtime_Access;
      Name    : String := "scope";
      Parent  : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Policy  : Aion.Cancel.Failure_Policy :=
        Aion.Cancel.Cancel_Siblings_On_Failure);

   function Spawn
     (Scope : in out Scope_Handle;
      Name  : String;
      Work  : Aion.Scheduler.Job_Procedure)
      return Aion.Runtime.Spawn_Results.Result_Type;

   function Close
     (Scope   : in out Scope_Handle;
      Timeout : Aion.Types.Milliseconds := 0)
      return Operation_Results.Result_Type;

   function Cancel
     (Scope  : in out Scope_Handle;
      Reason : String := "scope cancelled")
      return Operation_Results.Result_Type;

   function Token_Of
     (Scope : Scope_Handle) return Aion.Cancel_Token.Cancel_Token;

   function Stats_Of
     (Scope : Scope_Handle) return Aion.Task_Group.Task_Group_Stats;

   generic
      with procedure Scope_Body (Scope : in out Scope_Handle);
   procedure With_Scope
     (Scope   : in out Scope_Handle;
      Runtime : Aion.Task_Group.Runtime_Access;
      Name    : String := "scoped-block";
      Parent  : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Timeout : Aion.Types.Milliseconds := 0);

private
   type Scope_Handle (Max_Tasks : Positive) is limited record
      Is_Open : Boolean := False;
      Group   : Aion.Task_Group.Task_Group (Max_Tasks);
   end record;

end Aion.Scope;
