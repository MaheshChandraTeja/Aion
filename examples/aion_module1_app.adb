with Ada.Text_IO;
with Aion;
with Aion.Config;
with Aion.Errors;
with Aion.Version;

procedure Aion_Module1_App is
   Config : constant Aion.Config.Runtime_Config :=
     Aion.Config.With_Workers
       (Aion.Config.With_Name (Aion.Config.Default, "aion-module1-example"),
        4);

   Validation : constant Aion.Config.Validation_Results.Result_Type :=
     Aion.Config.Validate (Config);
begin
   Ada.Text_IO.Put_Line (Aion.Name & " " & Aion.Version.Full);
   Ada.Text_IO.Put_Line (Aion.Description);

   if Aion.Config.Validation_Results.Is_Err (Validation) then
      Ada.Text_IO.Put_Line
        ("Invalid config: " &
         Aion.Errors.Image (Aion.Config.Validation_Results.Error (Validation)));
      return;
   end if;

   Aion.Initialize;
   Ada.Text_IO.Put_Line ("Initialized: " & Boolean'Image (Aion.Is_Initialized));
   Ada.Text_IO.Put_Line (Aion.Config.Image (Config));
   Aion.Finalize;
   Ada.Text_IO.Put_Line ("Initialized after finalize: " & Boolean'Image (Aion.Is_Initialized));
end Aion_Module1_App;
