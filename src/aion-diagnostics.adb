with Interfaces;
with Aion.Types;
with Ada.Strings.Fixed;
with Aion.Config;
with Aion.Errors;
with Aion.Tracing;
with Aion.Version;

package body Aion.Diagnostics is
   use type Interfaces.Unsigned_64;
   use type Aion.Types.Runtime_State;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function Natural_Image (Value : Natural) return String is
   begin
      return Trim (Natural'Image (Value));
   end Natural_Image;

   function U64_To_Natural (Value : Interfaces.Unsigned_64) return Natural is
   begin
      if Value > Interfaces.Unsigned_64 (Natural'Last) then
         return Natural'Last;
      else
         return Natural (Value);
      end if;
   end U64_To_Natural;

   function Inspect_Runtime
     (Runtime : in out Aion.Runtime.Runtime_Handle)
      return Runtime_Health is
      Snapshot : constant Aion.Metrics.Metrics_Snapshot :=
        Aion.Metrics.From_Runtime (Runtime);
      Status : Health_Status := Health_Good;
   begin
      if Snapshot.Runtime.Failed_Tasks > 0 or else
         Snapshot.Runtime.Rejected_Tasks > 0
      then
         Status := Health_Degraded;
      end if;

      if Aion.Runtime.State_Of (Runtime) = Aion.Types.Runtime_Failed then
         Status := Health_Failed;
      end if;

      return
        (Status => Status,
         Active_Tasks => U64_To_Natural (Snapshot.Runtime.Active_Tasks),
         Queue_Depth => Snapshot.Runtime.Queue_Depth,
         Queue_Capacity => Snapshot.Runtime.Queue_Capacity,
         Failed_Tasks => U64_To_Natural (Snapshot.Runtime.Failed_Tasks),
         Cancelled_Tasks => U64_To_Natural (Snapshot.Runtime.Cancelled_Tasks),
         Reactor_Resources => Snapshot.Reactor.Registered_Resources,
         Timer_Pending => Snapshot.Timers.Pending,
         Trace_Events => Aion.Tracing.Count);
   end Inspect_Runtime;

   function Validate_Runtime
     (Runtime : in out Aion.Runtime.Runtime_Handle)
      return Operation_Results.Result_Type is
      Config_Result : constant Aion.Config.Validation_Results.Result_Type :=
        Aion.Config.Validate (Aion.Runtime.Config_Of (Runtime));
      Health : constant Runtime_Health := Inspect_Runtime (Runtime);
   begin
      if Aion.Config.Validation_Results.Is_Err (Config_Result) then
         return Operation_Results.Failure (Aion.Config.Validation_Results.Error (Config_Result));
      end if;

      if Health.Status = Health_Failed then
         return Operation_Results.Failure
           (Aion.Errors.Runtime_Error,
            "runtime health is failed",
            "Aion.Diagnostics.Validate_Runtime");
      end if;

      return Operation_Results.Success (True);
   end Validate_Runtime;

   function Validate_Release_Metadata
     (Expected_Version : String;
      Expected_Name    : String := "Aion") return Operation_Results.Result_Type is
      Actual_Version : constant String := Aion.Version.Semver;
      Actual_Name : constant String := Aion.Name;
   begin
      if Actual_Name /= Expected_Name then
         return Operation_Results.Failure
           (Aion.Errors.Configuration_Error,
            "unexpected library name: " & Actual_Name,
            "Aion.Diagnostics.Validate_Release_Metadata");
      end if;

      if Expected_Version'Length > 0 and then Actual_Version /= Expected_Version then
         return Operation_Results.Failure
           (Aion.Errors.Configuration_Error,
            "unexpected library version: " & Actual_Version,
            "Aion.Diagnostics.Validate_Release_Metadata");
      end if;

      return Operation_Results.Success (True);
   end Validate_Release_Metadata;

   function Report
     (Runtime : in out Aion.Runtime.Runtime_Handle)
      return String is
      Health : constant Runtime_Health := Inspect_Runtime (Runtime);
      Snapshot : constant Aion.Metrics.Metrics_Snapshot := Aion.Metrics.From_Runtime (Runtime);
   begin
      return "Aion diagnostic report: " & Image (Health) & "; " &
        Aion.Metrics.Image (Snapshot);
   end Report;

   function Report
     (Snapshot : Aion.Metrics.Metrics_Snapshot)
      return String is
   begin
      return "Aion metrics report: " & Aion.Metrics.Image (Snapshot);
   end Report;

   function Image (Status : Health_Status) return String is
   begin
      case Status is
         when Health_Good => return "good";
         when Health_Degraded => return "degraded";
         when Health_Failed => return "failed";
      end case;
   end Image;

   function Image (Health : Runtime_Health) return String is
   begin
      return "Runtime_Health(status=" & Image (Health.Status) &
        ", active=" & Natural_Image (Health.Active_Tasks) &
        ", queue=" & Natural_Image (Health.Queue_Depth) & "/" &
          Natural_Image (Health.Queue_Capacity) &
        ", failed=" & Natural_Image (Health.Failed_Tasks) &
        ", cancelled=" & Natural_Image (Health.Cancelled_Tasks) &
        ", reactor_resources=" & Natural_Image (Health.Reactor_Resources) &
        ", timer_pending=" & Natural_Image (Health.Timer_Pending) &
        ", traces=" & Natural_Image (Health.Trace_Events) & ")";
   end Image;
end Aion.Diagnostics;
