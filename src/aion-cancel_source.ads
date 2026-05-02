--  Cancellation source owns the authority to request cancellation.
--  Tokens are handed to workers; sources stay with supervisors/scopes/groups.

with Aion.Cancel_Token;
with Aion.Clock;
with Aion.Types;

package Aion.Cancel_Source is

   type Cancel_Source is tagged private;

   Null_Source : constant Cancel_Source;

   package Operation_Results renames Aion.Cancel_Token.Operation_Results;

   function Create
     (Name         : String := "cancel-source";
      Parent       : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Has_Deadline : Boolean := False;
      Deadline     : Aion.Clock.Instant := Aion.Clock.Epoch)
      return Cancel_Source;

   function With_Timeout
     (Name     : String;
      Parent   : Aion.Cancel_Token.Cancel_Token;
      Timeout  : Aion.Types.Milliseconds) return Cancel_Source;

   function Token_Of
     (Source : Cancel_Source) return Aion.Cancel_Token.Cancel_Token;

   function Is_Valid (Source : Cancel_Source) return Boolean;
   function Is_Cancelled (Source : Cancel_Source) return Boolean;

   function Cancel
     (Source : Cancel_Source;
      Reason : String := "operation cancelled";
      Origin : String := "Aion.Cancel_Source.Cancel")
      return Operation_Results.Result_Type;

   function Child_Source
     (Source : Cancel_Source;
      Name   : String := "child-cancel-source")
      return Cancel_Source;

   function Image (Source : Cancel_Source) return String;

private
   type Cancel_Source is tagged record
      Token : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
   end record;

   Null_Source : constant Cancel_Source :=
     (Token => Aion.Cancel_Token.Null_Token);

end Aion.Cancel_Source;
