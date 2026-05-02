with Aion.Config;
with Aion.Errors;
with Aion.Types;
with Test_Support;

procedure Test_Config is
   use type Aion.Errors.Error_Code;
   use type Aion.Types.Log_Level;
   use type Aion.Types.Shutdown_Mode;
   Default_Config : constant Aion.Config.Runtime_Config := Aion.Config.Default;
   Validated      : constant Aion.Config.Validation_Results.Result_Type :=
     Aion.Config.Validate (Default_Config);

   Tuned_Config : constant Aion.Config.Runtime_Config :=
     Aion.Config.With_Metrics
       (Aion.Config.With_Tracing
          (Aion.Config.With_Log_Level
             (Aion.Config.With_Shutdown_Mode
                (Aion.Config.With_Shutdown_Timeout
                   (Aion.Config.With_Max_Queue_Depth
                      (Aion.Config.With_Workers
                         (Aion.Config.With_Name
                            (Aion.Config.Default, "test-runtime"),
                          4),
                       8_192),
                    Aion.Types.Milliseconds'(10_000)),
                 Aion.Types.Shutdown_Immediate),
              Aion.Types.Log_Debug),
           True),
        False);

   Invalid_Workers : constant Aion.Config.Runtime_Config :=
     Aion.Config.With_Workers (Aion.Config.Default, 0);

   Invalid_Result : constant Aion.Config.Validation_Results.Result_Type :=
     Aion.Config.Validate (Invalid_Workers);

begin
   Test_Support.Section ("config");

   Test_Support.Assert
     (Aion.Config.Validation_Results.Is_Ok (Validated),
      "default config should validate");

   Test_Support.Assert
     (Aion.Config.Name_Of (Tuned_Config) = "test-runtime",
      "config name should round-trip");

   Test_Support.Assert
     (Aion.Config.Workers_Of (Tuned_Config) = 4,
      "worker count should round-trip");

   Test_Support.Assert
     (Aion.Config.Effective_Workers_Of (Tuned_Config) = 4,
      "effective workers should be typed worker count");

   Test_Support.Assert
     (Aion.Config.Max_Queue_Depth_Of (Tuned_Config) = 8_192,
      "queue depth should round-trip");

   Test_Support.Assert
     (Aion.Config.Shutdown_Mode_Of (Tuned_Config) = Aion.Types.Shutdown_Immediate,
      "shutdown mode should round-trip");

   Test_Support.Assert
     (Aion.Config.Log_Level_Of (Tuned_Config) = Aion.Types.Log_Debug,
      "log level should round-trip");

   Test_Support.Assert
     (Aion.Config.Tracing_Enabled (Tuned_Config),
      "tracing flag should round-trip");

   Test_Support.Assert
     (not Aion.Config.Metrics_Enabled (Tuned_Config),
      "metrics flag should round-trip");

   Test_Support.Assert
     (Aion.Config.Validation_Results.Is_Err (Invalid_Result),
      "invalid worker count should fail validation");

   Test_Support.Assert
     (Aion.Errors.Code_Of
        (Aion.Config.Validation_Results.Error (Invalid_Result)) =
        Aion.Errors.Configuration_Error,
      "invalid config should return configuration error");

   Test_Support.Assert
     (Aion.Config.Image (Tuned_Config)'Length > 0,
      "config image should not be empty");

   Test_Support.Pass ("runtime config behaves correctly");
end Test_Config;
