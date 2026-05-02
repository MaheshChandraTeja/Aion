--  Copy-safe cooperative cancellation token.

with Ada.Finalization;
with Ada.Strings.Unbounded;
with Aion.Clock;
with Aion.Cancel;
with Aion.Errors;
with Aion.Result;
with Aion.Types;
with Aion.Waker;

package Aion.Cancel_Token is

   type Cancel_Token is new Ada.Finalization.Controlled with private;

   Null_Token : constant Cancel_Token;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);

   function No_Parent return Cancel_Token;

   function Create
     (Name         : String := "cancel-token";
      Parent       : Cancel_Token := No_Parent;
      Has_Deadline : Boolean := False;
      Deadline     : Aion.Clock.Instant := Aion.Clock.Epoch)
      return Cancel_Token;

   function Is_Valid (Token : Cancel_Token) return Boolean;
   function Name_Of (Token : Cancel_Token) return String;

   function Is_Cancelled (Token : Cancel_Token) return Boolean;
   function Is_Deadline_Expired (Token : Cancel_Token) return Boolean;
   function Has_Deadline (Token : Cancel_Token) return Boolean;
   function Deadline_Of (Token : Cancel_Token) return Aion.Clock.Instant;
   function Parent_Of (Token : Cancel_Token) return Cancel_Token;

   function Reason_Of (Token : Cancel_Token) return String;
   function Error_Of (Token : Cancel_Token) return Aion.Errors.Error;

   function Cancel
     (Token  : Cancel_Token;
      Reason : String := "operation cancelled";
      Origin : String := "Aion.Cancel_Token.Cancel")
      return Operation_Results.Result_Type;

   function Attach_Waker
     (Token : Cancel_Token;
      Waker : Aion.Waker.Waker) return Operation_Results.Result_Type;

   function Await_Cancelled
     (Token : Cancel_Token) return Operation_Results.Result_Type;

   function Await_Cancelled_Timeout
     (Token   : Cancel_Token;
      Timeout : Aion.Types.Milliseconds) return Operation_Results.Result_Type;

   function Check
     (Token  : Cancel_Token;
      Origin : String := "Aion.Cancel_Token.Check")
      return Operation_Results.Result_Type;

   procedure Raise_If_Cancelled
     (Token  : Cancel_Token;
      Origin : String := "Aion.Cancel_Token.Raise_If_Cancelled");

   function Snapshot_State
     (Token : Cancel_Token) return Aion.Cancel.Cancellation_State;

   function Image (Token : Cancel_Token) return String;

private
   package US renames Ada.Strings.Unbounded;

   protected type State_Cell is
      procedure Retain;
      procedure Release (Remaining : out Natural);

      procedure Request_Cancel
        (Reason   : in String;
         Origin   : in String;
         Accepted : out Boolean);

      procedure Attach_Waker (Item : Aion.Waker.Waker);

      entry Wait_Until_Cancelled;

      function Cancelled return Boolean;
      function Reason return String;
      function Failure return Aion.Errors.Error;
      function References return Natural;
      function Wake_Count return Natural;
   private
      Ref_Count        : Natural := 1;
      Is_Set           : Boolean := False;
      Cancel_Reason    : US.Unbounded_String := US.Null_Unbounded_String;
      Failure_Info     : Aion.Errors.Error := Aion.Errors.Ok;
      Registered_Waker : Aion.Waker.Waker := Aion.Waker.Noop;
      Wake_Total       : Natural := 0;
   end State_Cell;

   type State_Cell_Access is access State_Cell;
   type Cancel_Token_Access is access Cancel_Token;

   type Cancel_Token is new Ada.Finalization.Controlled with record
      Name              : US.Unbounded_String := US.Null_Unbounded_String;
      Parent            : Cancel_Token_Access := null;
      Has_Deadline_Flag : Boolean := False;
      Deadline_Value    : Aion.Clock.Instant := Aion.Clock.Epoch;
      Cell              : State_Cell_Access := null;
   end record;

   overriding procedure Adjust (Token : in out Cancel_Token);
   overriding procedure Finalize (Token : in out Cancel_Token);

   Null_Token : constant Cancel_Token :=
     (Ada.Finalization.Controlled with
      Name              => US.Null_Unbounded_String,
      Parent            => null,
      Has_Deadline_Flag => False,
      Deadline_Value    => Aion.Clock.Epoch,
      Cell              => null);

end Aion.Cancel_Token;
