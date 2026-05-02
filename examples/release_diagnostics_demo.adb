with Aion.Errors;
with Ada.Text_IO;
with Aion.Diagnostics;

procedure Release_Diagnostics_Demo is
   Result : constant Aion.Diagnostics.Operation_Results.Result_Type :=
     Aion.Diagnostics.Validate_Release_Metadata
       (Expected_Version => "",
        Expected_Name    => "Aion");
begin
   if Aion.Diagnostics.Operation_Results.Is_Ok (Result) then
      Ada.Text_IO.Put_Line ("Aion release metadata check passed.");
   else
      Ada.Text_IO.Put_Line ("Aion release metadata check failed: " &
        Aion.Errors.Image (Aion.Diagnostics.Operation_Results.Error (Result)));
   end if;
end Release_Diagnostics_Demo;
