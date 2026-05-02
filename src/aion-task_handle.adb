with Ada.Unchecked_Deallocation;
with Aion.Task_Id;

package body Aion.Task_Handle is

   procedure Free is new Ada.Unchecked_Deallocation (State_Cell, State_Cell_Access);

   protected body State_Cell is
      procedure Retain is
      begin
         if Ref_Count < Natural'Last then
            Ref_Count := Ref_Count + 1;
         end if;
      end Retain;

      procedure Release (Remaining : out Natural) is
      begin
         if Ref_Count > 0 then
            Ref_Count := Ref_Count - 1;
         end if;

         Remaining := Ref_Count;
      end Release;

      procedure Set_State (State : Aion.Types.Task_State) is
      begin
         Current_State := State;
      end Set_State;

      procedure Set_Error (Failure : Aion.Errors.Error) is
      begin
         Failure_Info := Failure;
      end Set_Error;

      function State return Aion.Types.Task_State is
      begin
         return Current_State;
      end State;

      function Last_Error return Aion.Errors.Error is
      begin
         return Failure_Info;
      end Last_Error;

      function References return Natural is
      begin
         return Ref_Count;
      end References;
   end State_Cell;

   overriding procedure Adjust (Handle : in out Task_Handle) is
   begin
      if Handle.Cell /= null then
         Handle.Cell.Retain;
      end if;
   end Adjust;

   overriding procedure Finalize (Handle : in out Task_Handle) is
      Remaining : Natural := 0;
      Old_Cell  : State_Cell_Access := Handle.Cell;
   begin
      if Old_Cell /= null then
         Old_Cell.Release (Remaining);

         if Remaining = 0 then
            Free (Old_Cell);
         end if;
      end if;

      Handle.Cell := null;
      Handle.Id := Aion.Types.No_Task;
      Handle.Name := US.Null_Unbounded_String;
   end Finalize;

   function Create
     (Id   : Aion.Types.Task_Id;
      Name : String) return Task_Handle is
      Result : Task_Handle;
   begin
      Result.Id := Id;
      Result.Name := US.To_Unbounded_String (Name);
      Result.Cell := new State_Cell;
      Result.Cell.Set_State (Aion.Types.Task_Scheduled);
      return Result;
   end Create;

   function Is_Valid (Handle : Task_Handle) return Boolean is
   begin
      return Handle.Cell /= null and then Aion.Task_Id.Is_Valid (Handle.Id);
   end Is_Valid;

   function Id_Of (Handle : Task_Handle) return Aion.Types.Task_Id is
   begin
      return Handle.Id;
   end Id_Of;

   function Name_Of (Handle : Task_Handle) return String is
   begin
      return US.To_String (Handle.Name);
   end Name_Of;

   function State_Of (Handle : Task_Handle) return Aion.Types.Task_State is
   begin
      if Handle.Cell = null then
         return Aion.Types.Task_Cancelled;
      end if;

      return Handle.Cell.State;
   end State_Of;

   function Last_Error_Of (Handle : Task_Handle) return Aion.Errors.Error is
   begin
      if Handle.Cell = null then
         return Aion.Errors.Make
           (Aion.Errors.Invalid_State,
            "task handle is not valid",
            "Aion.Task_Handle.Last_Error_Of");
      end if;

      return Handle.Cell.Last_Error;
   end Last_Error_Of;

   function Is_Done (Handle : Task_Handle) return Boolean is
   begin
      return Aion.Types.Is_Terminal (State_Of (Handle));
   end Is_Done;

   function Image (Handle : Task_Handle) return String is
   begin
      if not Is_Valid (Handle) then
         return "Task_Handle(null)";
      end if;

      return
        "Task_Handle(id=" & Aion.Task_Id.Image (Handle.Id) &
        ", name=" & Name_Of (Handle) &
        ", state=" & Aion.Types.Image (State_Of (Handle)) &
        ")";
   end Image;

   procedure Mark_Scheduled (Handle : in out Task_Handle) is
   begin
      if Handle.Cell /= null then
         Handle.Cell.Set_State (Aion.Types.Task_Scheduled);
      end if;
   end Mark_Scheduled;

   procedure Mark_Running (Handle : in out Task_Handle) is
   begin
      if Handle.Cell /= null then
         Handle.Cell.Set_State (Aion.Types.Task_Running);
      end if;
   end Mark_Running;

   procedure Mark_Completed (Handle : in out Task_Handle) is
   begin
      if Handle.Cell /= null then
         Handle.Cell.Set_State (Aion.Types.Task_Completed);
      end if;
   end Mark_Completed;

   procedure Mark_Cancelled
     (Handle : in out Task_Handle;
      Reason : String := "task cancelled") is
   begin
      if Handle.Cell /= null then
         Handle.Cell.Set_Error
           (Aion.Errors.Make
              (Aion.Errors.Cancelled,
               Reason,
               "Aion.Task_Handle.Mark_Cancelled"));
         Handle.Cell.Set_State (Aion.Types.Task_Cancelled);
      end if;
   end Mark_Cancelled;

   procedure Mark_Faulted
     (Handle : in out Task_Handle;
      Failure : Aion.Errors.Error) is
   begin
      if Handle.Cell /= null then
         Handle.Cell.Set_Error (Failure);
         Handle.Cell.Set_State (Aion.Types.Task_Faulted);
      end if;
   end Mark_Faulted;

end Aion.Task_Handle;
