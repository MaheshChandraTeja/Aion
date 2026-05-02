with Aion.Errors;
with Aion.Result;
with Test_Support;

procedure Test_Result is
   use type Aion.Errors.Error_Code;
   package Integer_Results is new Aion.Result.Generic_Result (Integer);

   Good : constant Integer_Results.Result_Type := Integer_Results.Success (42);
   Bad  : constant Integer_Results.Result_Type :=
     Integer_Results.Failure
       (Aion.Errors.Invalid_Argument,
        "bad integer",
        "test_result");
begin
   Test_Support.Section ("result");

   Test_Support.Assert
     (Integer_Results.Is_Ok (Good),
      "success result should be ok");

   Test_Support.Assert
     (Integer_Results.Value (Good) = 42,
      "success result value should round-trip");

   Test_Support.Assert
     (Integer_Results.Is_Err (Bad),
      "failure result should be err");

   Test_Support.Assert
     (Aion.Errors.Code_Of (Integer_Results.Error (Bad)) = Aion.Errors.Invalid_Argument,
      "failure result error should round-trip");

   Test_Support.Assert
     (Integer_Results.Value_Or (Bad, 7) = 7,
      "Value_Or should return fallback for failed result");

   Test_Support.Pass ("generic result behaves correctly");
end Test_Result;
