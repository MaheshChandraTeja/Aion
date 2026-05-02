with Aion.Errors;
with Aion.Net;
with Test_Support;

procedure Test_Net_Errors is
   use type Aion.Errors.Error_Code;
   Result : constant Aion.Net.Operation_Results.Result_Type :=
     Aion.Net.Failure (Aion.Errors.Io_Error, "synthetic network failure", "Test_Net_Errors");
begin
   Test_Support.Section ("network error result model");
   Test_Support.Assert (Aion.Net.Operation_Results.Is_Err (Result), "network failure result should be failed");
   Test_Support.Assert
     (Aion.Errors.Code_Of (Aion.Net.Operation_Results.Error (Result)) = Aion.Errors.Io_Error,
      "network failure should preserve Io_Error code");
   Test_Support.Pass (Aion.Errors.Image (Aion.Net.Operation_Results.Error (Result)));
end Test_Net_Errors;
