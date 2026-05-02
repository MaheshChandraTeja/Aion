with Ada.Strings.Fixed;
with Aion.Errors;

package body Aion.Config is
   use type Aion.Types.Milliseconds;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function Natural_Text (Value : Natural) return String is
   begin
      return Trim (Natural'Image (Value));
   end Natural_Text;

   function Millisecond_Text (Value : Aion.Types.Milliseconds) return String is
   begin
      return Trim (Aion.Types.Milliseconds'Image (Value));
   end Millisecond_Text;

   function Default return Runtime_Config is
   begin
      return Runtime_Config'(others => <>);
   end Default;

   function With_Name
     (Config : Runtime_Config;
      Name   : String) return Runtime_Config is
      Updated : Runtime_Config := Config;
   begin
      Updated.Runtime_Name := US.To_Unbounded_String (Name);
      return Updated;
   end With_Name;

   function With_Workers
     (Config  : Runtime_Config;
      Workers : Natural) return Runtime_Config is
      Updated : Runtime_Config := Config;
   begin
      Updated.Workers := Workers;
      return Updated;
   end With_Workers;

   function With_Max_Queue_Depth
     (Config : Runtime_Config;
      Depth  : Natural) return Runtime_Config is
      Updated : Runtime_Config := Config;
   begin
      Updated.Max_Queue_Depth := Depth;
      return Updated;
   end With_Max_Queue_Depth;

   function With_Shutdown_Timeout
     (Config  : Runtime_Config;
      Timeout : Aion.Types.Milliseconds) return Runtime_Config is
      Updated : Runtime_Config := Config;
   begin
      Updated.Shutdown_Timeout_Ms := Timeout;
      return Updated;
   end With_Shutdown_Timeout;

   function With_Shutdown_Mode
     (Config : Runtime_Config;
      Mode   : Aion.Types.Shutdown_Mode) return Runtime_Config is
      Updated : Runtime_Config := Config;
   begin
      Updated.Shutdown_Mode := Mode;
      return Updated;
   end With_Shutdown_Mode;

   function With_Log_Level
     (Config : Runtime_Config;
      Level  : Aion.Types.Log_Level) return Runtime_Config is
      Updated : Runtime_Config := Config;
   begin
      Updated.Log_Level := Level;
      return Updated;
   end With_Log_Level;

   function With_Tracing
     (Config  : Runtime_Config;
      Enabled : Boolean) return Runtime_Config is
      Updated : Runtime_Config := Config;
   begin
      Updated.Enable_Tracing := Enabled;
      return Updated;
   end With_Tracing;

   function With_Metrics
     (Config  : Runtime_Config;
      Enabled : Boolean) return Runtime_Config is
      Updated : Runtime_Config := Config;
   begin
      Updated.Enable_Metrics := Enabled;
      return Updated;
   end With_Metrics;

   function Name_Of (Config : Runtime_Config) return String is
   begin
      return US.To_String (Config.Runtime_Name);
   end Name_Of;

   function Workers_Of (Config : Runtime_Config) return Natural is
   begin
      return Config.Workers;
   end Workers_Of;

   function Effective_Workers_Of
     (Config : Runtime_Config) return Aion.Types.Worker_Count is
   begin
      if Config.Workers < Aion.Types.Worker_Count'First then
         return Aion.Types.Worker_Count'First;
      elsif Config.Workers > Aion.Types.Worker_Count'Last then
         return Aion.Types.Worker_Count'Last;
      else
         return Aion.Types.Worker_Count (Config.Workers);
      end if;
   end Effective_Workers_Of;

   function Max_Queue_Depth_Of (Config : Runtime_Config) return Natural is
   begin
      return Config.Max_Queue_Depth;
   end Max_Queue_Depth_Of;

   function Shutdown_Timeout_Of
     (Config : Runtime_Config) return Aion.Types.Milliseconds is
   begin
      return Config.Shutdown_Timeout_Ms;
   end Shutdown_Timeout_Of;

   function Shutdown_Mode_Of
     (Config : Runtime_Config) return Aion.Types.Shutdown_Mode is
   begin
      return Config.Shutdown_Mode;
   end Shutdown_Mode_Of;

   function Log_Level_Of
     (Config : Runtime_Config) return Aion.Types.Log_Level is
   begin
      return Config.Log_Level;
   end Log_Level_Of;

   function Tracing_Enabled (Config : Runtime_Config) return Boolean is
   begin
      return Config.Enable_Tracing;
   end Tracing_Enabled;

   function Metrics_Enabled (Config : Runtime_Config) return Boolean is
   begin
      return Config.Enable_Metrics;
   end Metrics_Enabled;

   function Validate
     (Config : Runtime_Config) return Validation_Results.Result_Type is
      Origin : constant String := "Aion.Config.Validate";
   begin
      if Name_Of (Config)'Length = 0 then
         return Validation_Results.Failure
           (Aion.Errors.Configuration_Error,
            "runtime name cannot be empty",
            Origin);
      end if;

      if Config.Workers < 1 or else Config.Workers > Max_Workers then
         return Validation_Results.Failure
           (Aion.Errors.Configuration_Error,
            "workers must be between 1 and " & Natural_Text (Max_Workers),
            Origin);
      end if;

      if Config.Max_Queue_Depth > Max_Queue_Depth then
         return Validation_Results.Failure
           (Aion.Errors.Configuration_Error,
            "max queue depth must be <= " & Natural_Text (Max_Queue_Depth),
            Origin);
      end if;

      if Config.Shutdown_Timeout_Ms > Max_Shutdown_Timeout_Ms then
         return Validation_Results.Failure
           (Aion.Errors.Configuration_Error,
            "shutdown timeout must be <= " & Millisecond_Text (Max_Shutdown_Timeout_Ms) & "ms",
            Origin);
      end if;

      return Validation_Results.Success (True);
   end Validate;

   function Image (Config : Runtime_Config) return String is
   begin
      return
        "Runtime_Config(name=" & Name_Of (Config) &
        ", workers=" & Natural_Text (Config.Workers) &
        ", max_queue_depth=" & Natural_Text (Config.Max_Queue_Depth) &
        ", shutdown_timeout=" & Millisecond_Text (Config.Shutdown_Timeout_Ms) & "ms" &
        ", shutdown_mode=" & Aion.Types.Image (Config.Shutdown_Mode) &
        ", log_level=" & Aion.Types.Image (Config.Log_Level) &
        ", tracing=" & Boolean'Image (Config.Enable_Tracing) &
        ", metrics=" & Boolean'Image (Config.Enable_Metrics) &
        ")";
   end Image;

end Aion.Config;
