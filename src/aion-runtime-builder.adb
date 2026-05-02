package body Aion.Runtime.Builder is

   function New_Builder return Builder is
   begin
      return Builder'(Config => Aion.Config.Default);
   end New_Builder;

   function From_Config (Config : Aion.Config.Runtime_Config) return Builder is
   begin
      return Builder'(Config => Config);
   end From_Config;

   function With_Name
     (Item : Builder;
      Name : String) return Builder is
   begin
      return Builder'(Config => Aion.Config.With_Name (Item.Config, Name));
   end With_Name;

   function With_Workers
     (Item    : Builder;
      Workers : Natural) return Builder is
   begin
      return Builder'(Config => Aion.Config.With_Workers (Item.Config, Workers));
   end With_Workers;

   function With_Max_Queue_Depth
     (Item  : Builder;
      Depth : Natural) return Builder is
   begin
      return Builder'(Config => Aion.Config.With_Max_Queue_Depth (Item.Config, Depth));
   end With_Max_Queue_Depth;

   function With_Shutdown_Timeout
     (Item    : Builder;
      Timeout : Aion.Types.Milliseconds) return Builder is
   begin
      return Builder'(Config => Aion.Config.With_Shutdown_Timeout (Item.Config, Timeout));
   end With_Shutdown_Timeout;

   function With_Shutdown_Mode
     (Item : Builder;
      Mode : Aion.Types.Shutdown_Mode) return Builder is
   begin
      return Builder'(Config => Aion.Config.With_Shutdown_Mode (Item.Config, Mode));
   end With_Shutdown_Mode;

   function With_Log_Level
     (Item  : Builder;
      Level : Aion.Types.Log_Level) return Builder is
   begin
      return Builder'(Config => Aion.Config.With_Log_Level (Item.Config, Level));
   end With_Log_Level;

   function With_Tracing
     (Item    : Builder;
      Enabled : Boolean) return Builder is
   begin
      return Builder'(Config => Aion.Config.With_Tracing (Item.Config, Enabled));
   end With_Tracing;

   function With_Metrics
     (Item    : Builder;
      Enabled : Boolean) return Builder is
   begin
      return Builder'(Config => Aion.Config.With_Metrics (Item.Config, Enabled));
   end With_Metrics;

   function Config_Of (Item : Builder) return Aion.Config.Runtime_Config is
   begin
      return Item.Config;
   end Config_Of;

   function Validate (Item : Builder) return Validation_Results.Result_Type is
      Config_Result : constant Aion.Config.Validation_Results.Result_Type :=
        Aion.Config.Validate (Item.Config);
   begin
      if Aion.Config.Validation_Results.Is_Err (Config_Result) then
         return Validation_Results.Failure
           (Aion.Config.Validation_Results.Error (Config_Result));
      end if;

      return Validation_Results.Success (True);
   end Validate;

   function Build (Item : Builder) return Aion.Runtime.Runtime_Handle is
   begin
      return Aion.Runtime.Create (Item.Config);
   end Build;

end Aion.Runtime.Builder;
