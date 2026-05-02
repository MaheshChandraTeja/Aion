with Test_Support;
with Aion.Cancel_Source;
with Aion.Cancel_Token;

procedure Test_Deadline_Propagation is
   Source : constant Aion.Cancel_Source.Cancel_Source :=
     Aion.Cancel_Source.With_Timeout
       (Name    => "deadline",
        Parent  => Aion.Cancel_Token.Null_Token,
        Timeout => 5);
   Token : constant Aion.Cancel_Token.Cancel_Token :=
     Aion.Cancel_Source.Token_Of (Source);
   R : Aion.Cancel_Token.Operation_Results.Result_Type;
begin
   Test_Support.Section ("deadline propagation");

   delay 0.020;

   Test_Support.Assert
     (Aion.Cancel_Token.Is_Cancelled (Token),
      "deadline-backed token should become cancelled after timeout");

   R := Aion.Cancel_Token.Check (Token);
   Test_Support.Assert
     (Aion.Cancel_Token.Operation_Results.Is_Err (R),
      "deadline token check should fail");

   Test_Support.Pass ("deadline expiry propagates through cancellation token checks");
end Test_Deadline_Propagation;
