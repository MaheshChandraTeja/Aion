with Aion.Completion;
with Aion.Errors;
with Aion.Future;
with Test_Support;

procedure Test_Future_Basic is
   use type Aion.Completion.Completion_State;
   use type Aion.Errors.Error_Code;

   package Int_Futures is new Aion.Future.Generic_Future (Integer);

   F : Int_Futures.Future_Handle;
   Pending_Value : Int_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("future basic");

   F := Int_Futures.Create (Name => "basic-future");

   Test_Support.Assert (Int_Futures.Is_Valid (F), "future is valid");
   Test_Support.Assert (Int_Futures.Name_Of (F) = "basic-future", "future stores name");
   Test_Support.Assert
     (Int_Futures.State_Of (F) = Aion.Completion.Completion_Pending,
      "new future starts pending");
   Test_Support.Assert (Int_Futures.Is_Pending (F), "pending helper works");

   Pending_Value := Int_Futures.Try_Value (F);
   Test_Support.Assert
     (Int_Futures.Value_Results.Is_Err (Pending_Value),
      "try value on pending future returns error");
   Test_Support.Assert
     (Aion.Errors.Code_Of (Int_Futures.Value_Results.Error (Pending_Value)) =
      Aion.Errors.Invalid_State,
      "pending try-value uses Invalid_State");

   Test_Support.Pass ("future construction and pending polling work");
end Test_Future_Basic;
