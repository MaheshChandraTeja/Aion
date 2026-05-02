with Test_Support;
with Aion.Cancel_Source;
with Aion.Cancel_Token;

procedure Test_Cancel_Source is
   Parent : constant Aion.Cancel_Source.Cancel_Source :=
     Aion.Cancel_Source.Create ("parent");
   Child : constant Aion.Cancel_Source.Cancel_Source :=
     Aion.Cancel_Source.Child_Source (Parent, "child");
   R : Aion.Cancel_Source.Operation_Results.Result_Type;
begin
   Test_Support.Section ("cancel source");

   Test_Support.Assert
     (not Aion.Cancel_Source.Is_Cancelled (Child),
      "child should start uncancelled");

   R := Aion.Cancel_Source.Cancel (Parent, "parent cancelled");
   Test_Support.Assert
     (Aion.Cancel_Source.Operation_Results.Is_Ok (R),
      "parent cancellation should succeed");
   Test_Support.Assert
     (Aion.Cancel_Source.Is_Cancelled (Parent),
      "parent should be cancelled");
   Test_Support.Assert
     (Aion.Cancel_Token.Is_Cancelled (Aion.Cancel_Source.Token_Of (Child)),
      "child token should observe parent cancellation");

   Test_Support.Pass ("cancel source propagates parent cancellation to child tokens");
end Test_Cancel_Source;
