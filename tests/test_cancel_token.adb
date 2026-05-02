with Test_Support;
with Aion.Cancel_Token;

procedure Test_Cancel_Token is
   Token : constant Aion.Cancel_Token.Cancel_Token :=
     Aion.Cancel_Token.Create ("unit-token");
   R : Aion.Cancel_Token.Operation_Results.Result_Type;
begin
   Test_Support.Section ("cancel token");

   Test_Support.Assert
     (Aion.Cancel_Token.Is_Valid (Token),
      "token should be valid after creation");
   Test_Support.Assert
     (not Aion.Cancel_Token.Is_Cancelled (Token),
      "token should start uncancelled");

   R := Aion.Cancel_Token.Cancel (Token, "unit cancellation");
   Test_Support.Assert
     (Aion.Cancel_Token.Operation_Results.Is_Ok (R),
      "cancel should succeed");
   Test_Support.Assert
     (Aion.Cancel_Token.Is_Cancelled (Token),
      "token should be cancelled");
   Test_Support.Assert
     (Aion.Cancel_Token.Reason_Of (Token) = "unit cancellation",
      "cancel reason should be retained");

   R := Aion.Cancel_Token.Check (Token);
   Test_Support.Assert
     (Aion.Cancel_Token.Operation_Results.Is_Err (R),
      "check should fail after cancellation");

   Test_Support.Pass ("cancel token supports creation, cancellation, and checks");
end Test_Cancel_Token;
