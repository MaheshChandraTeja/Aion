with Test_Support;
with Aion.Diagnostics;

procedure Test_Release_Integrity is
   Result : Aion.Diagnostics.Operation_Results.Result_Type;
begin
   Test_Support.Section ("release integrity");
   Result := Aion.Diagnostics.Validate_Release_Metadata
     (Expected_Version => "",
      Expected_Name    => "Aion");
   Test_Support.Assert (Aion.Diagnostics.Operation_Results.Is_Ok (Result), "release metadata should identify Aion");
   Test_Support.Pass ("release integrity checks work");
end Test_Release_Integrity;
