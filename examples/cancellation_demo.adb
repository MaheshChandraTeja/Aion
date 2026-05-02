with Ada.Text_IO;
with Aion.Cancel_Source;
with Aion.Cancel_Token;

procedure Cancellation_Demo is
   Root  : constant Aion.Cancel_Source.Cancel_Source :=
     Aion.Cancel_Source.Create ("demo-root");
   Child : constant Aion.Cancel_Source.Cancel_Source :=
     Aion.Cancel_Source.Child_Source (Root, "demo-child");
   R : Aion.Cancel_Source.Operation_Results.Result_Type;
begin
   Ada.Text_IO.Put_Line ("Aion cancellation demo");

   R := Aion.Cancel_Source.Cancel (Root, "operator requested shutdown");

   if Aion.Cancel_Source.Operation_Results.Is_Ok (R)
     and then Aion.Cancel_Token.Is_Cancelled
       (Aion.Cancel_Source.Token_Of (Child))
   then
      Ada.Text_IO.Put_Line ("Child token observed parent cancellation.");
      Ada.Text_IO.Put_Line
        ("Reason: " &
         Aion.Cancel_Token.Reason_Of
           (Aion.Cancel_Source.Token_Of (Child)));
   else
      Ada.Text_IO.Put_Line ("Cancellation failed.");
   end if;
end Cancellation_Demo;
