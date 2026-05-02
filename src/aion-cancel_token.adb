with Ada.Unchecked_Deallocation;

package body Aion.Cancel_Token is

   procedure Free_Cell is new Ada.Unchecked_Deallocation
     (State_Cell, State_Cell_Access);

   procedure Free_Token is new Ada.Unchecked_Deallocation
     (Cancel_Token, Cancel_Token_Access);

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

      procedure Request_Cancel
        (Reason   : in String;
         Origin   : in String;
         Accepted : out Boolean) is
      begin
         if Is_Set then
            Accepted := False;
            return;
         end if;

         Is_Set := True;
         Cancel_Reason := US.To_Unbounded_String (Reason);
         Failure_Info := Aion.Errors.Make
           (Aion.Errors.Cancelled,
            Reason,
            Origin);

         if not Aion.Waker.Is_Noop (Registered_Waker) then
            Aion.Waker.Wake (Registered_Waker);
            Wake_Total := Wake_Total + 1;
         end if;

         Accepted := True;
      end Request_Cancel;

      procedure Attach_Waker (Item : Aion.Waker.Waker) is
      begin
         Registered_Waker := Item;
         if Is_Set and then not Aion.Waker.Is_Noop (Registered_Waker) then
            Aion.Waker.Wake (Registered_Waker);
            Wake_Total := Wake_Total + 1;
         end if;
      end Attach_Waker;

      entry Wait_Until_Cancelled when Is_Set is
      begin
         null;
      end Wait_Until_Cancelled;

      function Cancelled return Boolean is
      begin
         return Is_Set;
      end Cancelled;

      function Reason return String is
      begin
         return US.To_String (Cancel_Reason);
      end Reason;

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

   function No_Parent return Cancel_Token is
   begin
      return Null_Token;
   end No_Parent;

   function Create
     (Name         : String := "cancel-token";
      Parent       : Cancel_Token := No_Parent;
      Has_Deadline : Boolean := False;
      Deadline     : Aion.Clock.Instant := Aion.Clock.Epoch)
      return Cancel_Token
   is
      Parent_Copy : Cancel_Token_Access := null;
   begin
      if Is_Valid (Parent) then
         Parent_Copy := new Cancel_Token'(Parent);
      end if;

      return
        (Ada.Finalization.Controlled with
         Name              => US.To_Unbounded_String (Name),
         Parent            => Parent_Copy,
         Has_Deadline_Flag => Has_Deadline,
         Deadline_Value    => Deadline,
         Cell              => new State_Cell);
   end Create;

   function Is_Valid (Token : Cancel_Token) return Boolean is
   begin
      return Token.Cell /= null;
   end Is_Valid;

   function Name_Of (Token : Cancel_Token) return String is
   begin
      return US.To_String (Token.Name);
   end Name_Of;

   function Is_Deadline_Expired (Token : Cancel_Token) return Boolean is
   begin
      return
        Token.Has_Deadline_Flag
        and then Aion.Clock.Has_Passed (Token.Deadline_Value);
   end Is_Deadline_Expired;

   function Is_Cancelled (Token : Cancel_Token) return Boolean is
   begin
      if not Is_Valid (Token) then
         return True;
      end if;

      if Token.Cell.Cancelled then
         return True;
      end if;

      if Token.Parent /= null and then Is_Cancelled (Token.Parent.all) then
         return True;
      end if;

      return Is_Deadline_Expired (Token);
   end Is_Cancelled;

   function Has_Deadline (Token : Cancel_Token) return Boolean is
   begin
      return Token.Has_Deadline_Flag;
   end Has_Deadline;

   function Deadline_Of (Token : Cancel_Token) return Aion.Clock.Instant is
   begin
      return Token.Deadline_Value;
   end Deadline_Of;

   function Parent_Of (Token : Cancel_Token) return Cancel_Token is
   begin
      if Token.Parent = null then
         return Null_Token;
      end if;

      return Token.Parent.all;
   end Parent_Of;

   function Reason_Of (Token : Cancel_Token) return String is
   begin
      if not Is_Valid (Token) then
         return "invalid cancellation token";
      elsif Token.Cell.Cancelled then
         return Token.Cell.Reason;
      elsif Token.Parent /= null and then Is_Cancelled (Token.Parent.all) then
         return Reason_Of (Token.Parent.all);
      elsif Is_Deadline_Expired (Token) then
         return "deadline expired";
      else
         return "";
      end if;
   end Reason_Of;

   function Error_Of (Token : Cancel_Token) return Aion.Errors.Error is
   begin
      if not Is_Valid (Token) then
         return Aion.Errors.Make
           (Aion.Errors.Invalid_State,
            "invalid cancellation token",
            "Aion.Cancel_Token.Error_Of");
      elsif Token.Cell.Cancelled then
         return Token.Cell.Failure;
      elsif Token.Parent /= null and then Is_Cancelled (Token.Parent.all) then
         return Error_Of (Token.Parent.all);
      elsif Is_Deadline_Expired (Token) then
         return Aion.Errors.Make
           (Aion.Errors.Timeout,
            "deadline expired",
            "Aion.Cancel_Token.Error_Of");
      else
         return Aion.Errors.Ok;
      end if;
   end Error_Of;

   function Cancel
     (Token  : Cancel_Token;
      Reason : String := "operation cancelled";
      Origin : String := "Aion.Cancel_Token.Cancel")
      return Operation_Results.Result_Type
   is
      Accepted : Boolean := False;
   begin
      if not Is_Valid (Token) then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "cannot cancel invalid token",
            Origin);
      end if;

      Token.Cell.Request_Cancel (Reason, Origin, Accepted);
      return Operation_Results.Success (Accepted);
   end Cancel;

   function Attach_Waker
     (Token : Cancel_Token;
      Waker : Aion.Waker.Waker) return Operation_Results.Result_Type is
   begin
      if not Is_Valid (Token) then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "cannot attach waker to invalid token",
            "Aion.Cancel_Token.Attach_Waker");
      end if;

      Token.Cell.Attach_Waker (Waker);
      return Operation_Results.Success (True);
   end Attach_Waker;

   function Await_Cancelled
     (Token : Cancel_Token) return Operation_Results.Result_Type is
   begin
      if not Is_Valid (Token) then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "cannot await invalid token",
            "Aion.Cancel_Token.Await_Cancelled");
      end if;

      if Is_Cancelled (Token) then
         return Operation_Results.Success (True);
      end if;

      Token.Cell.Wait_Until_Cancelled;

      if Is_Cancelled (Token) then
         return Operation_Results.Success (True);
      else
         return Operation_Results.Failure
           (Aion.Errors.Internal_Error,
            "cancel wait returned before token was cancelled",
            "Aion.Cancel_Token.Await_Cancelled");
      end if;
   end Await_Cancelled;

   function Await_Cancelled_Timeout
     (Token   : Cancel_Token;
      Timeout : Aion.Types.Milliseconds) return Operation_Results.Result_Type
   is
      Seconds : constant Duration :=
        Duration (Long_Float (Timeout) / 1000.0);
   begin
      if not Is_Valid (Token) then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "cannot await invalid token",
            "Aion.Cancel_Token.Await_Cancelled_Timeout");
      end if;

      if Is_Cancelled (Token) then
         return Operation_Results.Success (True);
      end if;

      select
         Token.Cell.Wait_Until_Cancelled;
         return Operation_Results.Success (True);
      or
         delay Seconds;
         if Is_Cancelled (Token) then
            return Operation_Results.Success (True);
         end if;

         return Operation_Results.Failure
           (Aion.Errors.Timeout,
            "timed out waiting for cancellation",
            "Aion.Cancel_Token.Await_Cancelled_Timeout");
      end select;
   end Await_Cancelled_Timeout;

   function Check
     (Token  : Cancel_Token;
      Origin : String := "Aion.Cancel_Token.Check")
      return Operation_Results.Result_Type is
   begin
      if not Is_Valid (Token) then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "invalid cancellation token",
            Origin);
      end if;

      if Is_Deadline_Expired (Token) then
         return Operation_Results.Failure
           (Aion.Errors.Timeout,
            "deadline expired",
            Origin);
      elsif Is_Cancelled (Token) then
         return Operation_Results.Failure
           (Aion.Errors.Cancelled,
            Reason_Of (Token),
            Origin);
      end if;

      return Operation_Results.Success (True);
   end Check;

   procedure Raise_If_Cancelled
     (Token  : Cancel_Token;
      Origin : String := "Aion.Cancel_Token.Raise_If_Cancelled")
   is
      Result : constant Operation_Results.Result_Type := Check (Token, Origin);
   begin
      if Operation_Results.Is_Err (Result) then
         Aion.Errors.Raise_If_Error (Operation_Results.Error (Result));
      end if;
   end Raise_If_Cancelled;

   function Snapshot_State
     (Token : Cancel_Token) return Aion.Cancel.Cancellation_State is
   begin
      if Is_Cancelled (Token) then
         return Aion.Cancel.Cancellation_Requested;
      else
         return Aion.Cancel.Not_Cancelled;
      end if;
   end Snapshot_State;

   function Image (Token : Cancel_Token) return String is
   begin
      if not Is_Valid (Token) then
         return "Cancel_Token(invalid)";
      end if;

      return
        "Cancel_Token(name=" & Name_Of (Token) &
        ", state=" & Aion.Cancel.Image (Snapshot_State (Token)) &
        ", reason=" & Reason_Of (Token) & ")";
   end Image;

   overriding procedure Adjust (Token : in out Cancel_Token) is
   begin
      if Token.Cell /= null then
         Token.Cell.Retain;
      end if;

      if Token.Parent /= null then
         Token.Parent := new Cancel_Token'(Token.Parent.all);
      end if;
   end Adjust;

   overriding procedure Finalize (Token : in out Cancel_Token) is
      Remaining : Natural := 0;
   begin
      if Token.Parent /= null then
         Free_Token (Token.Parent);
      end if;

      if Token.Cell /= null then
         Token.Cell.Release (Remaining);
         if Remaining = 0 then
            Free_Cell (Token.Cell);
         else
            Token.Cell := null;
         end if;
      end if;
   end Finalize;

end Aion.Cancel_Token;
