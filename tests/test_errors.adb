with Aion.Errors;
with Test_Support;

procedure Test_Errors is
   use type Aion.Errors.Error_Code;
   Item : constant Aion.Errors.Error :=
     Aion.Errors.Make
       (Aion.Errors.Configuration_Error,
        "bad config",
        "test");
begin
   Test_Support.Section ("errors");

   Test_Support.Assert
     (Aion.Errors.Has_Error (Item),
      "constructed error should report Has_Error");

   Test_Support.Assert
     (Aion.Errors.Code_Of (Item) = Aion.Errors.Configuration_Error,
      "error code should round-trip");

   Test_Support.Assert
     (Aion.Errors.Message_Of (Item) = "bad config",
      "message should round-trip");

   Test_Support.Assert
     (Aion.Errors.Origin_Of (Item) = "test",
      "origin should round-trip");

   Test_Support.Assert
     (Aion.Errors.Image (Aion.Errors.Timeout) = "timeout",
      "error code image should be stable");

   Test_Support.Assert
     (Aion.Errors.Is_Retryable (Aion.Errors.Timeout),
      "timeout should be retryable");

   Test_Support.Assert
     (not Aion.Errors.Is_Retryable (Aion.Errors.Invalid_Argument),
      "invalid argument should not be retryable");

   Test_Support.Pass ("structured errors behave correctly");
end Test_Errors;
