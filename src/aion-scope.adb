with Aion.Errors;

package body Aion.Scope is

   procedure Open
     (Scope   : in out Scope_Handle;
      Runtime : Aion.Task_Group.Runtime_Access;
      Name    : String := "scope";
      Parent  : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Policy  : Aion.Cancel.Failure_Policy :=
        Aion.Cancel.Cancel_Siblings_On_Failure) is
   begin
      Aion.Task_Group.Initialize
        (Group   => Scope.Group,
         Runtime => Runtime,
         Name    => Name,
         Parent  => Parent,
         Policy  => Policy);
      Scope.Is_Open := True;
   end Open;

   function Spawn
     (Scope : in out Scope_Handle;
      Name  : String;
      Work  : Aion.Scheduler.Job_Procedure)
      return Aion.Runtime.Spawn_Results.Result_Type is
   begin
      if not Scope.Is_Open then
         return Aion.Runtime.Spawn_Results.Failure
           (Aion.Errors.Invalid_State,
            "cannot spawn into closed scope",
            "Aion.Scope.Spawn");
      end if;

      return Aion.Task_Group.Spawn (Scope.Group, Name, Work);
   end Spawn;

   function Close
     (Scope   : in out Scope_Handle;
      Timeout : Aion.Types.Milliseconds := 0)
      return Operation_Results.Result_Type
   is
      R : Aion.Task_Group.Operation_Results.Result_Type;
   begin
      if not Scope.Is_Open then
         return Operation_Results.Success (True);
      end if;

      R := Aion.Task_Group.Join_All (Scope.Group, Timeout);
      Scope.Is_Open := False;

      if Aion.Task_Group.Operation_Results.Is_Err (R) then
         return Operation_Results.Failure
           (Aion.Task_Group.Operation_Results.Error (R));
      end if;

      return Operation_Results.Success (True);
   end Close;

   function Cancel
     (Scope  : in out Scope_Handle;
      Reason : String := "scope cancelled")
      return Operation_Results.Result_Type
   is
      R : constant Aion.Task_Group.Operation_Results.Result_Type :=
        Aion.Task_Group.Cancel (Scope.Group, Reason);
   begin
      Scope.Is_Open := False;

      if Aion.Task_Group.Operation_Results.Is_Err (R) then
         return Operation_Results.Failure
           (Aion.Task_Group.Operation_Results.Error (R));
      end if;

      return Operation_Results.Success (True);
   end Cancel;

   function Token_Of
     (Scope : Scope_Handle) return Aion.Cancel_Token.Cancel_Token is
   begin
      return Aion.Task_Group.Token_Of (Scope.Group);
   end Token_Of;

   function Stats_Of
     (Scope : Scope_Handle) return Aion.Task_Group.Task_Group_Stats is
   begin
      return Aion.Task_Group.Stats_Of (Scope.Group);
   end Stats_Of;

   procedure With_Scope
     (Scope   : in out Scope_Handle;
      Runtime : Aion.Task_Group.Runtime_Access;
      Name    : String := "scoped-block";
      Parent  : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Timeout : Aion.Types.Milliseconds := 0) is
   begin
      Open
        (Scope   => Scope,
         Runtime => Runtime,
         Name    => Name,
         Parent  => Parent);

      begin
         Scope_Body (Scope);
      exception
         when others =>
            declare
               Ignored : constant Operation_Results.Result_Type :=
                 Cancel (Scope, "scope body raised exception");
            begin
               null;
            end;
            raise;
      end;

      declare
         Ignored : constant Operation_Results.Result_Type :=
           Close (Scope, Timeout);
      begin
         null;
      end;
   end With_Scope;

end Aion.Scope;
