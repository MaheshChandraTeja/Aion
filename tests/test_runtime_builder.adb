with Aion.Config;
with Aion.Runtime;
with Aion.Runtime.Builder;
with Aion.Types;
with Test_Support;

procedure Test_Runtime_Builder is
   use type Aion.Types.Runtime_State;
   function Make_Builder return Aion.Runtime.Builder.Builder is
      Item : Aion.Runtime.Builder.Builder := Aion.Runtime.Builder.New_Builder;
   begin
      Item := Aion.Runtime.Builder.With_Name (Item, "builder-test");
      Item := Aion.Runtime.Builder.With_Workers (Item, 3);
      Item := Aion.Runtime.Builder.With_Max_Queue_Depth (Item, 128);
      Item := Aion.Runtime.Builder.With_Shutdown_Mode (Item, Aion.Types.Shutdown_Graceful);
      Item := Aion.Runtime.Builder.With_Log_Level (Item, Aion.Types.Log_Debug);
      Item := Aion.Runtime.Builder.With_Tracing (Item, True);
      Item := Aion.Runtime.Builder.With_Metrics (Item, True);
      return Item;
   end Make_Builder;

   Builder : constant Aion.Runtime.Builder.Builder := Make_Builder;
   Validation : constant Aion.Runtime.Builder.Validation_Results.Result_Type :=
     Aion.Runtime.Builder.Validate (Builder);

   Runtime : constant Aion.Runtime.Runtime_Handle := Aion.Runtime.Builder.Build (Builder);
   Config  : constant Aion.Config.Runtime_Config := Aion.Runtime.Config_Of (Runtime);
begin
   Test_Support.Section ("runtime builder");

   Test_Support.Assert
     (Aion.Runtime.Builder.Validation_Results.Is_Ok (Validation),
      "builder validates config");
   Test_Support.Assert
     (Aion.Config.Name_Of (Config) = "builder-test",
      "builder writes runtime name");
   Test_Support.Assert
     (Aion.Config.Workers_Of (Config) = 3,
      "builder writes worker count");
   Test_Support.Assert
     (Aion.Runtime.State_Of (Runtime) = Aion.Types.Runtime_Created,
      "builder creates a created runtime");

   Test_Support.Pass ("runtime builder works");
end Test_Runtime_Builder;
