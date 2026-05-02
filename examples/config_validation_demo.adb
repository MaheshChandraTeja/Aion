with Ada.Text_IO;
with Aion.Config;
with Aion.Errors;

procedure Config_Validation_Demo is
   Bad_Config : constant Aion.Config.Runtime_Config :=
     Aion.Config.With_Workers (Aion.Config.Default, 0);

   Result : constant Aion.Config.Validation_Results.Result_Type :=
     Aion.Config.Validate (Bad_Config);
begin
   if Aion.Config.Validation_Results.Is_Err (Result) then
      Ada.Text_IO.Put_Line
        ("Expected validation failure: " &
         Aion.Errors.Image (Aion.Config.Validation_Results.Error (Result)));
   else
      Ada.Text_IO.Put_Line ("Unexpected success. The config goblin escaped.");
   end if;
end Config_Validation_Demo;
