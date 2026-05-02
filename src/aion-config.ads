--  Runtime configuration for Aion.

with Ada.Strings.Unbounded;
with Aion.Types;
with Aion.Result;

package Aion.Config is

   type Runtime_Config is tagged private;

   package Validation_Results is new Aion.Result.Generic_Result (Boolean);

   Default_Workers             : constant Natural := 1;
   Default_Max_Queue_Depth     : constant Natural := 4_096;
   Default_Shutdown_Timeout_Ms : constant Aion.Types.Milliseconds := 30_000;
   Max_Workers                 : constant Natural := 256;
   Max_Queue_Depth             : constant Natural := 1_000_000;
   Max_Shutdown_Timeout_Ms     : constant Aion.Types.Milliseconds := 3_600_000;

   function Default return Runtime_Config;

   function With_Name
     (Config : Runtime_Config;
      Name   : String) return Runtime_Config;

   function With_Workers
     (Config  : Runtime_Config;
      Workers : Natural) return Runtime_Config;

   function With_Max_Queue_Depth
     (Config : Runtime_Config;
      Depth  : Natural) return Runtime_Config;

   function With_Shutdown_Timeout
     (Config  : Runtime_Config;
      Timeout : Aion.Types.Milliseconds) return Runtime_Config;

   function With_Shutdown_Mode
     (Config : Runtime_Config;
      Mode   : Aion.Types.Shutdown_Mode) return Runtime_Config;

   function With_Log_Level
     (Config : Runtime_Config;
      Level  : Aion.Types.Log_Level) return Runtime_Config;

   function With_Tracing
     (Config  : Runtime_Config;
      Enabled : Boolean) return Runtime_Config;

   function With_Metrics
     (Config  : Runtime_Config;
      Enabled : Boolean) return Runtime_Config;

   function Name_Of (Config : Runtime_Config) return String;
   function Workers_Of (Config : Runtime_Config) return Natural;
   function Effective_Workers_Of
     (Config : Runtime_Config) return Aion.Types.Worker_Count;
   function Max_Queue_Depth_Of (Config : Runtime_Config) return Natural;
   function Shutdown_Timeout_Of
     (Config : Runtime_Config) return Aion.Types.Milliseconds;
   function Shutdown_Mode_Of
     (Config : Runtime_Config) return Aion.Types.Shutdown_Mode;
   function Log_Level_Of
     (Config : Runtime_Config) return Aion.Types.Log_Level;
   function Tracing_Enabled (Config : Runtime_Config) return Boolean;
   function Metrics_Enabled (Config : Runtime_Config) return Boolean;

   function Validate
     (Config : Runtime_Config) return Validation_Results.Result_Type;

   function Image (Config : Runtime_Config) return String;

private
   package US renames Ada.Strings.Unbounded;

   type Runtime_Config is tagged record
      Runtime_Name        : US.Unbounded_String := US.To_Unbounded_String ("aion-runtime");
      Workers             : Natural := Default_Workers;
      Max_Queue_Depth     : Natural := Default_Max_Queue_Depth;
      Shutdown_Timeout_Ms : Aion.Types.Milliseconds := Default_Shutdown_Timeout_Ms;
      Shutdown_Mode       : Aion.Types.Shutdown_Mode := Aion.Types.Shutdown_Graceful;
      Log_Level           : Aion.Types.Log_Level := Aion.Types.Log_Info;
      Enable_Tracing      : Boolean := False;
      Enable_Metrics      : Boolean := True;
   end record;

end Aion.Config;
