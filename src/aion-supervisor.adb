with Ada.Real_Time;
with Ada.Strings.Fixed;
with Aion.Errors;

package body Aion.Supervisor is
   use type Aion.Scheduler.Job_Procedure;
   use type Aion.Types.Milliseconds;
   use type Interfaces.Unsigned_64;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   procedure Store_Name (Child : in out Child_Record; Name : String) is
      Len : constant Natural := Natural'Min (Name'Length, Child.Name'Length);
   begin
      Child.Name := (others => ' ');
      if Len > 0 then
         Child.Name (1 .. Len) := Name (Name'First .. Name'First + Len - 1);
      end if;
      Child.Name_Len := Len;
   end Store_Name;

   function Child_Name (Child : Child_Record) return String is
   begin
      if Child.Name_Len = 0 then
         return "";
      end if;
      return Child.Name (1 .. Child.Name_Len);
   end Child_Name;

   procedure Initialize
     (Item    : in out Supervisor;
      Runtime : Runtime_Access;
      Name    : String := "supervisor";
      Config  : Supervisor_Config := (others => <>);
      Parent  : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token) is
   begin
      Item.Runtime := Runtime;
      Item.Source := Aion.Cancel_Source.Create
        (Name   => Name & ".cancel",
         Parent => Parent);
      Item.Config := Config;

      for I in Item.Children'Range loop
         Item.Children (I) :=
           (Used     => False,
            Name     => (others => ' '),
            Name_Len => 0,
            Work     => null,
            Handle   => Aion.Task_Handle.Null_Handle,
            Restarts => 0);
      end loop;
   end Initialize;

   function Spawn
     (Item : in out Supervisor;
      Name : String;
      Work : Aion.Scheduler.Job_Procedure)
      return Aion.Runtime.Spawn_Results.Result_Type
   is
      Result : Aion.Runtime.Spawn_Results.Result_Type;
   begin
      if Item.Runtime = null then
         return Aion.Runtime.Spawn_Results.Failure
           (Aion.Errors.Invalid_State,
            "supervisor has no runtime",
            "Aion.Supervisor.Spawn");
      elsif Work = null then
         return Aion.Runtime.Spawn_Results.Failure
           (Aion.Errors.Invalid_Argument,
            "supervised work procedure cannot be null",
            "Aion.Supervisor.Spawn");
      elsif Aion.Cancel_Source.Is_Cancelled (Item.Source) then
         return Aion.Runtime.Spawn_Results.Failure
           (Aion.Errors.Cancelled,
            "supervisor is cancelled",
            "Aion.Supervisor.Spawn");
      end if;

      for I in Item.Children'Range loop
         if not Item.Children (I).Used then
            Result := Aion.Runtime.Spawn (Item.Runtime.all, Name, Work);
            if Aion.Runtime.Spawn_Results.Is_Err (Result) then
               return Result;
            end if;

            Item.Children (I).Used := True;
            Store_Name (Item.Children (I), Name);
            Item.Children (I).Work := Work;
            Item.Children (I).Handle := Aion.Runtime.Spawn_Results.Value (Result);
            Item.Children (I).Restarts := 0;
            return Result;
         end if;
      end loop;

      return Aion.Runtime.Spawn_Results.Failure
        (Aion.Errors.Capacity_Exceeded,
         "supervisor child capacity exceeded",
         "Aion.Supervisor.Spawn");
   end Spawn;

   function Restart_Child
     (Item  : in out Supervisor;
      Index : Positive) return Operation_Results.Result_Type
   is
      Child : Child_Record renames Item.Children (Index);
      Result : Aion.Runtime.Spawn_Results.Result_Type;
   begin
      if Item.Runtime = null or else Child.Work = null then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "cannot restart child without runtime and work",
            "Aion.Supervisor.Restart_Child");
      end if;

      if Child.Restarts >= Item.Config.Max_Restarts then
         return Operation_Results.Failure
           (Aion.Errors.Runtime_Error,
            "child exceeded restart budget",
            "Aion.Supervisor.Restart_Child");
      end if;

      if Item.Config.Restart_Delay_Ms > 0 then
         delay Duration (Long_Float (Item.Config.Restart_Delay_Ms) / 1000.0);
      end if;

      Result := Aion.Runtime.Spawn (Item.Runtime.all, Child_Name (Child), Child.Work);
      if Aion.Runtime.Spawn_Results.Is_Err (Result) then
         return Operation_Results.Failure
           (Aion.Runtime.Spawn_Results.Error (Result));
      end if;

      Child.Handle := Aion.Runtime.Spawn_Results.Value (Result);
      Child.Restarts := Child.Restarts + 1;
      return Operation_Results.Success (True);
   end Restart_Child;

   function Tick
     (Item : in out Supervisor) return Operation_Results.Result_Type is
   begin
      if Aion.Cancel_Source.Is_Cancelled (Item.Source) then
         return Operation_Results.Failure
           (Aion.Errors.Cancelled,
            "supervisor is cancelled",
            "Aion.Supervisor.Tick");
      end if;

      for I in Item.Children'Range loop
         if Item.Children (I).Used then
            case Aion.Task_Handle.State_Of (Item.Children (I).Handle) is
               when Aion.Types.Task_Faulted =>
                  case Item.Config.Policy is
                     when Ignore_Failures =>
                        null;

                     when Cancel_All_On_First_Failure =>
                        return Cancel_All
                          (Item,
                           "supervisor cancelling children after first failure");

                     when Restart_Failed_Children =>
                        declare
                           R : constant Operation_Results.Result_Type :=
                             Restart_Child (Item, I);
                        begin
                           if Operation_Results.Is_Err (R) then
                              return R;
                           end if;
                        end;
                  end case;

               when others =>
                  null;
            end case;
         end if;
      end loop;

      return Operation_Results.Success (True);
   end Tick;

   function Run_Until_Stable
     (Item    : in out Supervisor;
      Timeout : Aion.Types.Milliseconds := 0)
      return Operation_Results.Result_Type
   is
      use Ada.Real_Time;
      Started : constant Time := Clock;
   begin
      loop
         declare
            R : constant Operation_Results.Result_Type := Tick (Item);
         begin
            if Operation_Results.Is_Err (R) then
               return R;
            end if;
         end;

         declare
            Stats : constant Supervisor_Stats := Stats_Of (Item);
         begin
            if Stats.Active = 0 then
               return Operation_Results.Success (True);
            end if;
         end;

         if Timeout > 0
           and then Clock - Started >= Milliseconds (Integer (Timeout))
         then
            return Operation_Results.Failure
              (Aion.Errors.Timeout,
               "supervisor did not stabilize before timeout",
               "Aion.Supervisor.Run_Until_Stable");
         end if;

         delay 0.001;
      end loop;
   end Run_Until_Stable;

   function Cancel_All
     (Item   : in out Supervisor;
      Reason : String := "supervisor cancelled")
      return Operation_Results.Result_Type
   is
      R : constant Aion.Cancel_Source.Operation_Results.Result_Type :=
        Aion.Cancel_Source.Cancel
          (Item.Source,
           Reason,
           "Aion.Supervisor.Cancel_All");
   begin
      if Aion.Cancel_Source.Operation_Results.Is_Err (R) then
         return Operation_Results.Failure
           (Aion.Cancel_Source.Operation_Results.Error (R));
      end if;

      for I in Item.Children'Range loop
         if Item.Children (I).Used
           and then not Aion.Task_Handle.Is_Done (Item.Children (I).Handle)
         then
            Aion.Task_Handle.Mark_Cancelled (Item.Children (I).Handle, Reason);
         end if;
      end loop;

      return Operation_Results.Success (True);
   end Cancel_All;

   function Token_Of
     (Item : Supervisor) return Aion.Cancel_Token.Cancel_Token is
   begin
      return Aion.Cancel_Source.Token_Of (Item.Source);
   end Token_Of;

   function Stats_Of (Item : Supervisor) return Supervisor_Stats is
      Stats : Supervisor_Stats;
   begin
      for I in Item.Children'Range loop
         if Item.Children (I).Used then
            Stats.Children := Stats.Children + 1;
            Stats.Restarts := Stats.Restarts + Interfaces.Unsigned_64 (Item.Children (I).Restarts);

            case Aion.Task_Handle.State_Of (Item.Children (I).Handle) is
               when Aion.Types.Task_Completed =>
                  Stats.Completed := Stats.Completed + 1;
               when Aion.Types.Task_Faulted =>
                  Stats.Failed := Stats.Failed + 1;
               when Aion.Types.Task_Cancelled =>
                  Stats.Cancelled := Stats.Cancelled + 1;
               when others =>
                  Stats.Active := Stats.Active + 1;
            end case;
         end if;
      end loop;

      return Stats;
   end Stats_Of;

   function Config_Of (Item : Supervisor) return Supervisor_Config is
   begin
      return Item.Config;
   end Config_Of;

   function Image (Policy : Supervisor_Policy) return String is
   begin
      case Policy is
         when Restart_Failed_Children =>
            return "restart_failed_children";
         when Cancel_All_On_First_Failure =>
            return "cancel_all_on_first_failure";
         when Ignore_Failures =>
            return "ignore_failures";
      end case;
   end Image;

   function Image (Stats : Supervisor_Stats) return String is
   begin
      return
        "Supervisor_Stats(children=" & Trim (Interfaces.Unsigned_64'Image (Stats.Children)) &
        ", active=" & Trim (Natural'Image (Stats.Active)) &
        ", restarts=" & Trim (Interfaces.Unsigned_64'Image (Stats.Restarts)) &
        ", failed=" & Trim (Interfaces.Unsigned_64'Image (Stats.Failed)) &
        ", cancelled=" & Trim (Interfaces.Unsigned_64'Image (Stats.Cancelled)) &
        ", completed=" & Trim (Interfaces.Unsigned_64'Image (Stats.Completed)) &
        ", rejected=" & Trim (Interfaces.Unsigned_64'Image (Stats.Restart_Rejected)) & ")";
   end Image;

end Aion.Supervisor;
