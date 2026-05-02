with Ada.Strings.Fixed;
with Ada.Unchecked_Deallocation;
with Aion.Task_Id;

package body Aion.Future is

   package body Generic_Future is
      use type Aion.Types.Task_Id;
      use type Aion.Completion.Completion_State;

      protected Id_Generator is
         procedure Next (Id : out Aion.Types.Task_Id);
      private
         Current : Aion.Types.Task_Id := 1;
      end Id_Generator;

      protected body Id_Generator is
         procedure Next (Id : out Aion.Types.Task_Id) is
         begin
            Id := Current;

            if Current = Aion.Types.Task_Id'Last then
               Current := 1;
            else
               Current := Current + 1;
            end if;
         end Next;
      end Id_Generator;

      procedure Free is new Ada.Unchecked_Deallocation
        (Object => State_Cell,
         Name   => State_Cell_Access);

      function Trim (Value : String) return String is
      begin
         return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
      end Trim;

      function Timeout_To_Duration
        (Timeout : Aion.Types.Milliseconds) return Duration is
      begin
         return Duration (Long_Float (Timeout) / 1_000.0);
      end Timeout_To_Duration;

      function Invalid_Future_Error return Aion.Errors.Error is
      begin
         return Aion.Errors.Make
           (Aion.Errors.Invalid_State,
            "future handle is null or no longer valid",
            "Aion.Future");
      end Invalid_Future_Error;

      function Result_From_State
        (Future : Future_Handle) return Value_Results.Result_Type is
         State : constant Aion.Completion.Completion_State := Future.Cell.State;
      begin
         case State is
            when Aion.Completion.Completion_Ready =>
               return Value_Results.Success (Future.Cell.Stored);

            when Aion.Completion.Completion_Failed | 
                 Aion.Completion.Completion_Cancelled |
                 Aion.Completion.Completion_Timed_Out =>
               return Value_Results.Failure (Future.Cell.Failure);

            when Aion.Completion.Completion_Pending =>
               return Value_Results.Failure
                 (Aion.Errors.Invalid_State,
                  "future is still pending",
                  "Aion.Future");
         end case;
      end Result_From_State;

      protected body State_Cell is
         procedure Retain is
         begin
            Ref_Count := Ref_Count + 1;
         end Retain;

         procedure Release (Remaining : out Natural) is
         begin
            if Ref_Count > 0 then
               Ref_Count := Ref_Count - 1;
            end if;

            Remaining := Ref_Count;
         end Release;

         procedure Attach_Waker (Item : Aion.Waker.Waker) is
         begin
            Registered_Waker := Item;

            if Aion.Completion.Is_Terminal (Current_State) then
               Aion.Waker.Wake (Registered_Waker);
               Wake_Total := Wake_Total + 1;
            end if;
         end Attach_Waker;

         procedure Complete_Success
           (Value    : in Value_Type;
            Accepted : out Boolean) is
         begin
            if Current_State /= Aion.Completion.Completion_Pending then
               Accepted := False;
               return;
            end if;

            Stored_Value := Value;
            Failure_Info := Aion.Errors.Ok;
            Current_State := Aion.Completion.Completion_Ready;
            Accepted := True;

            Aion.Waker.Wake (Registered_Waker);
            Wake_Total := Wake_Total + 1;
         end Complete_Success;

         procedure Complete_Error
           (State    : in Aion.Completion.Completion_State;
            Failure  : in Aion.Errors.Error;
            Accepted : out Boolean) is
         begin
            if Current_State /= Aion.Completion.Completion_Pending then
               Accepted := False;
               return;
            end if;

            if State = Aion.Completion.Completion_Pending or else
               State = Aion.Completion.Completion_Ready
            then
               Current_State := Aion.Completion.Completion_Failed;
            else
               Current_State := State;
            end if;

            Failure_Info := Failure;
            Accepted := True;

            Aion.Waker.Wake (Registered_Waker);
            Wake_Total := Wake_Total + 1;
         end Complete_Error;

         entry Wait_Until_Done
           when Current_State /= Aion.Completion.Completion_Pending is
         begin
            null;
         end Wait_Until_Done;

         function State return Aion.Completion.Completion_State is
         begin
            return Current_State;
         end State;

         function Stored return Value_Type is
         begin
            return Stored_Value;
         end Stored;

         function Failure return Aion.Errors.Error is
         begin
            return Failure_Info;
         end Failure;

         function References return Natural is
         begin
            return Ref_Count;
         end References;

         function Wake_Count return Natural is
         begin
            return Wake_Total;
         end Wake_Count;
      end State_Cell;

      function Create
        (Name        : String := "";
         Source_Task : Aion.Task_Handle.Task_Handle :=
           Aion.Task_Handle.Null_Handle) return Future_Handle is
         Id : Aion.Types.Task_Id;
      begin
         Id_Generator.Next (Id);

         return
           (Ada.Finalization.Controlled with
            Id          => Id,
            Name        => US.To_Unbounded_String (Name),
            Source_Task => Source_Task,
            Cell        => new State_Cell);
      end Create;

      function Is_Valid (Future : Future_Handle) return Boolean is
      begin
         return Future.Id /= Aion.Types.No_Task and then Future.Cell /= null;
      end Is_Valid;

      function Id_Of (Future : Future_Handle) return Aion.Types.Task_Id is
      begin
         return Future.Id;
      end Id_Of;

      function Name_Of (Future : Future_Handle) return String is
      begin
         return US.To_String (Future.Name);
      end Name_Of;

      function State_Of
        (Future : Future_Handle) return Aion.Completion.Completion_State is
      begin
         if not Is_Valid (Future) then
            return Aion.Completion.Completion_Failed;
         end if;

         return Future.Cell.State;
      end State_Of;

      function Source_Task_Of
        (Future : Future_Handle) return Aion.Task_Handle.Task_Handle is
      begin
         return Future.Source_Task;
      end Source_Task_Of;

      function Snapshot_Of (Future : Future_Handle) return Future_Snapshot is
      begin
         if not Is_Valid (Future) then
            return
              (Id          => Aion.Types.No_Task,
               State       => Aion.Completion.Completion_Failed,
               Source_Task => Aion.Task_Handle.Null_Handle,
               Wake_Count  => 0);
         end if;

         return
           (Id          => Future.Id,
            State       => Future.Cell.State,
            Source_Task => Future.Source_Task,
            Wake_Count  => Future.Cell.Wake_Count);
      end Snapshot_Of;

      function Is_Pending (Future : Future_Handle) return Boolean is
      begin
         return Is_Valid (Future) and then
           Future.Cell.State = Aion.Completion.Completion_Pending;
      end Is_Pending;

      function Is_Ready (Future : Future_Handle) return Boolean is
      begin
         return Is_Valid (Future) and then
           Future.Cell.State = Aion.Completion.Completion_Ready;
      end Is_Ready;

      function Is_Done (Future : Future_Handle) return Boolean is
      begin
         return Is_Valid (Future) and then
           Aion.Completion.Is_Terminal (Future.Cell.State);
      end Is_Done;

      function Is_Failed (Future : Future_Handle) return Boolean is
      begin
         return Is_Valid (Future) and then
           Aion.Completion.Is_Failure (Future.Cell.State);
      end Is_Failed;

      function Try_Value (Future : Future_Handle) return Value_Results.Result_Type is
      begin
         if not Is_Valid (Future) then
            return Value_Results.Failure (Invalid_Future_Error);
         end if;

         return Result_From_State (Future);
      end Try_Value;

      function Await (Future : Future_Handle) return Value_Results.Result_Type is
      begin
         if not Is_Valid (Future) then
            return Value_Results.Failure (Invalid_Future_Error);
         end if;

         Future.Cell.Wait_Until_Done;
         return Result_From_State (Future);
      end Await;

      function Await_Timeout
        (Future  : Future_Handle;
         Timeout : Aion.Types.Milliseconds) return Value_Results.Result_Type is
         Did_Timeout : Boolean := False;
      begin
         if not Is_Valid (Future) then
            return Value_Results.Failure (Invalid_Future_Error);
         end if;

         select
            Future.Cell.Wait_Until_Done;
         or
            delay Timeout_To_Duration (Timeout);
            Did_Timeout := True;
         end select;

         if Did_Timeout then
            return Value_Results.Failure
              (Aion.Errors.Timeout,
               "future await timed out after" &
                 Aion.Types.Image (Timeout) & " ms",
               "Aion.Future");
         end if;

         return Result_From_State (Future);
      end Await_Timeout;

      function Error_Of (Future : Future_Handle) return Aion.Errors.Error is
      begin
         if not Is_Valid (Future) then
            return Invalid_Future_Error;
         end if;

         return Future.Cell.Failure;
      end Error_Of;

      function Attach_Waker
        (Future : Future_Handle;
         Waker  : Aion.Waker.Waker) return Operation_Results.Result_Type is
      begin
         if not Is_Valid (Future) then
            return Operation_Results.Failure (Invalid_Future_Error);
         end if;

         Future.Cell.Attach_Waker (Waker);
         return Operation_Results.Success (True);
      end Attach_Waker;

      function Image (Future : Future_Handle) return String is
      begin
         if not Is_Valid (Future) then
            return "future[id=0,state=invalid]";
         end if;

         return Image (Snapshot_Of (Future));
      end Image;

      function Image (Snapshot : Future_Snapshot) return String is
      begin
         return
           "future[id=" & Aion.Task_Id.Image (Snapshot.Id) &
           ",state=" & Aion.Completion.Image (Snapshot.State) &
           ",source_task=" & Aion.Task_Handle.Image (Snapshot.Source_Task) &
           ",wake_count=" & Trim (Natural'Image (Snapshot.Wake_Count)) &
           "]";
      end Image;

      function Complete_Success
        (Future : Future_Handle;
         Value  : Value_Type) return Operation_Results.Result_Type is
         Accepted : Boolean := False;
      begin
         if not Is_Valid (Future) then
            return Operation_Results.Failure (Invalid_Future_Error);
         end if;

         Future.Cell.Complete_Success (Value, Accepted);

         if not Accepted then
            return Operation_Results.Failure
              (Aion.Errors.Invalid_State,
               "future has already completed",
               "Aion.Future");
         end if;

         return Operation_Results.Success (True);
      end Complete_Success;

      function Complete_Failure
        (Future  : Future_Handle;
         Failure : Aion.Errors.Error) return Operation_Results.Result_Type is
         Accepted : Boolean := False;
      begin
         if not Is_Valid (Future) then
            return Operation_Results.Failure (Invalid_Future_Error);
         end if;

         Future.Cell.Complete_Error
           (Aion.Completion.Completion_Failed, Failure, Accepted);

         if not Accepted then
            return Operation_Results.Failure
              (Aion.Errors.Invalid_State,
               "future has already completed",
               "Aion.Future");
         end if;

         return Operation_Results.Success (True);
      end Complete_Failure;

      function Complete_Failure
        (Future  : Future_Handle;
         Code    : Aion.Errors.Error_Code;
         Message : String;
         Origin  : String := "") return Operation_Results.Result_Type is
      begin
         return Complete_Failure
           (Future,
            Aion.Errors.Make (Code, Message, Origin));
      end Complete_Failure;

      function Complete_Cancelled
        (Future : Future_Handle;
         Reason : String := "future cancelled") return Operation_Results.Result_Type is
         Accepted : Boolean := False;
      begin
         if not Is_Valid (Future) then
            return Operation_Results.Failure (Invalid_Future_Error);
         end if;

         Future.Cell.Complete_Error
           (Aion.Completion.Completion_Cancelled,
            Aion.Errors.Make (Aion.Errors.Cancelled, Reason, "Aion.Future"),
            Accepted);

         if not Accepted then
            return Operation_Results.Failure
              (Aion.Errors.Invalid_State,
               "future has already completed",
               "Aion.Future");
         end if;

         return Operation_Results.Success (True);
      end Complete_Cancelled;

      function Complete_Timed_Out
        (Future : Future_Handle;
         Reason : String := "future timed out") return Operation_Results.Result_Type is
         Accepted : Boolean := False;
      begin
         if not Is_Valid (Future) then
            return Operation_Results.Failure (Invalid_Future_Error);
         end if;

         Future.Cell.Complete_Error
           (Aion.Completion.Completion_Timed_Out,
            Aion.Errors.Make (Aion.Errors.Timeout, Reason, "Aion.Future"),
            Accepted);

         if not Accepted then
            return Operation_Results.Failure
              (Aion.Errors.Invalid_State,
               "future has already completed",
               "Aion.Future");
         end if;

         return Operation_Results.Success (True);
      end Complete_Timed_Out;

      overriding procedure Adjust (Future : in out Future_Handle) is
      begin
         if Future.Cell /= null then
            Future.Cell.Retain;
         end if;
      end Adjust;

      overriding procedure Finalize (Future : in out Future_Handle) is
         Remaining : Natural := 0;
      begin
         if Future.Cell /= null then
            Future.Cell.Release (Remaining);

            if Remaining = 0 then
               Free (Future.Cell);
            end if;

            Future.Cell := null;
         end if;
      end Finalize;

   end Generic_Future;

end Aion.Future;
