with Ada.Strings.Fixed;
with Aion.Errors;

package body Aion.Task_Group is
   use type Interfaces.Unsigned_64;
   use type Aion.Cancel.Failure_Policy;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   procedure Set_Name (Group : in out Task_Group; Name : String) is
      Len : constant Natural := Natural'Min (Name'Length, Group.Name'Length);
   begin
      Group.Name := (others => ' ');
      if Len > 0 then
         Group.Name (1 .. Len) := Name (Name'First .. Name'First + Len - 1);
      end if;
      Group.Name_Len := Len;
   end Set_Name;

   procedure Initialize
     (Group  : in out Task_Group;
      Runtime : Runtime_Access;
      Name    : String := "task-group";
      Parent  : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Policy  : Aion.Cancel.Failure_Policy :=
        Aion.Cancel.Cancel_Siblings_On_Failure) is
   begin
      Group.Runtime := Runtime;
      Group.Policy := Policy;
      Group.Source := Aion.Cancel_Source.Create
        (Name   => Name & ".cancel",
         Parent => Parent);
      Aion.Join_Set.Clear (Group.Set);
      Set_Name (Group, Name);
   end Initialize;

   function Spawn
     (Group : in out Task_Group;
      Name  : String;
      Work  : Aion.Scheduler.Job_Procedure)
      return Aion.Runtime.Spawn_Results.Result_Type
   is
      Result : Aion.Runtime.Spawn_Results.Result_Type;
      Add_Result : Aion.Join_Set.Operation_Results.Result_Type;
   begin
      if Group.Runtime = null then
         return Aion.Runtime.Spawn_Results.Failure
           (Aion.Errors.Invalid_State,
            "task group has no runtime",
            "Aion.Task_Group.Spawn");
      end if;

      if Aion.Cancel_Source.Is_Cancelled (Group.Source) then
         return Aion.Runtime.Spawn_Results.Failure
           (Aion.Errors.Cancelled,
            "task group is already cancelled",
            "Aion.Task_Group.Spawn");
      end if;

      Result := Aion.Runtime.Spawn (Group.Runtime.all, Name, Work);
      if Aion.Runtime.Spawn_Results.Is_Err (Result) then
         return Result;
      end if;

      Add_Result := Aion.Join_Set.Add
        (Group.Set,
         Aion.Runtime.Spawn_Results.Value (Result));

      if Aion.Join_Set.Operation_Results.Is_Err (Add_Result) then
         return Aion.Runtime.Spawn_Results.Failure
           (Aion.Join_Set.Operation_Results.Error (Add_Result));
      end if;

      return Result;
   end Spawn;

   function Join_All
     (Group   : in out Task_Group;
      Timeout : Aion.Types.Milliseconds := 0)
      return Operation_Results.Result_Type
   is
      Result : constant Aion.Join_Set.Operation_Results.Result_Type :=
        Aion.Join_Set.Join_All
          (Set     => Group.Set,
           Token   => Aion.Cancel_Source.Token_Of (Group.Source),
           Timeout => Timeout);
      Stats : constant Task_Group_Stats := Stats_Of (Group);
   begin
      if Aion.Join_Set.Operation_Results.Is_Err (Result) then
         return Operation_Results.Failure
           (Aion.Join_Set.Operation_Results.Error (Result));
      end if;

      if Group.Policy /= Aion.Cancel.Continue_On_Failure
        and then Stats.Failed > 0
      then
         declare
            C : constant Operation_Results.Result_Type :=
              Cancel (Group, "task group failed; cancelling siblings");
         begin
            if Operation_Results.Is_Err (C) then
               return C;
            end if;
         end;
      end if;

      return Operation_Results.Success (True);
   end Join_All;

   function Cancel
     (Group  : in out Task_Group;
      Reason : String := "task group cancelled")
      return Operation_Results.Result_Type
   is
      Source_Result : constant Aion.Cancel_Source.Operation_Results.Result_Type :=
        Aion.Cancel_Source.Cancel
          (Group.Source,
           Reason,
           "Aion.Task_Group.Cancel");
      Set_Result : constant Aion.Join_Set.Operation_Results.Result_Type :=
        Aion.Join_Set.Cancel_All (Group.Set, Reason);
   begin
      if Aion.Cancel_Source.Operation_Results.Is_Err (Source_Result) then
         return Operation_Results.Failure
           (Aion.Cancel_Source.Operation_Results.Error (Source_Result));
      end if;

      if Aion.Join_Set.Operation_Results.Is_Err (Set_Result) then
         return Operation_Results.Failure
           (Aion.Join_Set.Operation_Results.Error (Set_Result));
      end if;

      return Operation_Results.Success (True);
   end Cancel;

   function Token_Of
     (Group : Task_Group) return Aion.Cancel_Token.Cancel_Token is
   begin
      return Aion.Cancel_Source.Token_Of (Group.Source);
   end Token_Of;

   function Stats_Of (Group : Task_Group) return Task_Group_Stats is
      Join_Stats : constant Aion.Join_Set.Join_Stats :=
        Aion.Join_Set.Stats_Of (Group.Set);
   begin
      return
        (Spawned   => Join_Stats.Registered,
         Completed => Join_Stats.Completed,
         Failed    => Join_Stats.Failed,
         Cancelled => Join_Stats.Cancelled,
         Pending   => Join_Stats.Pending);
   end Stats_Of;

   function Count_Of (Group : Task_Group) return Natural is
   begin
      return Aion.Join_Set.Count_Of (Group.Set);
   end Count_Of;

   function Pending_Of (Group : Task_Group) return Natural is
   begin
      return Aion.Join_Set.Pending_Of (Group.Set);
   end Pending_Of;

   function Is_Cancelled (Group : Task_Group) return Boolean is
   begin
      return Aion.Cancel_Source.Is_Cancelled (Group.Source);
   end Is_Cancelled;

   function Image (Stats : Task_Group_Stats) return String is
   begin
      return
        "Task_Group_Stats(spawned=" & Trim (Interfaces.Unsigned_64'Image (Stats.Spawned)) &
        ", completed=" & Trim (Interfaces.Unsigned_64'Image (Stats.Completed)) &
        ", failed=" & Trim (Interfaces.Unsigned_64'Image (Stats.Failed)) &
        ", cancelled=" & Trim (Interfaces.Unsigned_64'Image (Stats.Cancelled)) &
        ", pending=" & Trim (Natural'Image (Stats.Pending)) & ")";
   end Image;

end Aion.Task_Group;
