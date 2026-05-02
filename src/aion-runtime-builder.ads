--  Fluent runtime builder for Aion.Runtime.
--  The builder reuses Aion.Config instead of creating another configuration
--  model, because duplicated config types are how neat projects become swamps.

with Aion.Config;
with Aion.Result;
with Aion.Types;

package Aion.Runtime.Builder is

   type Builder is tagged private;

   package Validation_Results is new Aion.Result.Generic_Result (Boolean);

   function New_Builder return Builder;
   function From_Config (Config : Aion.Config.Runtime_Config) return Builder;

   function With_Name
     (Item : Builder;
      Name : String) return Builder;

   function With_Workers
     (Item    : Builder;
      Workers : Natural) return Builder;

   function With_Max_Queue_Depth
     (Item  : Builder;
      Depth : Natural) return Builder;

   function With_Shutdown_Timeout
     (Item    : Builder;
      Timeout : Aion.Types.Milliseconds) return Builder;

   function With_Shutdown_Mode
     (Item : Builder;
      Mode : Aion.Types.Shutdown_Mode) return Builder;

   function With_Log_Level
     (Item  : Builder;
      Level : Aion.Types.Log_Level) return Builder;

   function With_Tracing
     (Item    : Builder;
      Enabled : Boolean) return Builder;

   function With_Metrics
     (Item    : Builder;
      Enabled : Boolean) return Builder;

   function Config_Of (Item : Builder) return Aion.Config.Runtime_Config;
   function Validate (Item : Builder) return Validation_Results.Result_Type;
   function Build (Item : Builder) return Aion.Runtime.Runtime_Handle;

private
   type Builder is tagged record
      Config : Aion.Config.Runtime_Config := Aion.Config.Default;
   end record;

end Aion.Runtime.Builder;
