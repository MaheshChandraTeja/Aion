with Test_Support;
with Aion.Cancel_Source;
with Aion.Cancel_Token;

procedure Test_Cancellation_Stress is
   Parent : constant Aion.Cancel_Source.Cancel_Source :=
     Aion.Cancel_Source.Create ("stress-parent");
   Children : array (1 .. 256) of Aion.Cancel_Source.Cancel_Source;
   R : Aion.Cancel_Source.Operation_Results.Result_Type;
begin
   Test_Support.Section ("cancellation stress");

   for I in Children'Range loop
      Children (I) := Aion.Cancel_Source.Child_Source
        (Parent,
         "stress-child");
   end loop;

   R := Aion.Cancel_Source.Cancel (Parent, "stress cancel");
   Test_Support.Assert
     (Aion.Cancel_Source.Operation_Results.Is_Ok (R),
      "parent cancellation should succeed");

   for I in Children'Range loop
      Test_Support.Assert
        (Aion.Cancel_Token.Is_Cancelled
           (Aion.Cancel_Source.Token_Of (Children (I))),
         "child token should observe stress parent cancellation");
   end loop;

   Test_Support.Pass ("cancellation propagates across many child tokens");
end Test_Cancellation_Stress;
