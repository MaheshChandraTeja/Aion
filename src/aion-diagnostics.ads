--  Aion diagnostics and health reports.
--
--  Diagnostics compose runtime metrics and tracing information into stable,
--  human-readable health summaries without reaching into module internals.

with Aion.Metrics;
with Aion.Result;
with Aion.Runtime;

package Aion.Diagnostics is
   pragma Elaborate_Body;

   type Health_Status is
     (Health_Good,
      Health_Degraded,
      Health_Failed);

   type Runtime_Health is record
      Status            : Health_Status := Health_Good;
      Active_Tasks      : Natural := 0;
      Queue_Depth       : Natural := 0;
      Queue_Capacity    : Natural := 0;
      Failed_Tasks      : Natural := 0;
      Cancelled_Tasks   : Natural := 0;
      Reactor_Resources : Natural := 0;
      Timer_Pending     : Natural := 0;
      Trace_Events      : Natural := 0;
   end record;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);

   function Inspect_Runtime
     (Runtime : in out Aion.Runtime.Runtime_Handle)
      return Runtime_Health;

   function Validate_Runtime
     (Runtime : in out Aion.Runtime.Runtime_Handle)
      return Operation_Results.Result_Type;

   function Validate_Release_Metadata
     (Expected_Version : String;
      Expected_Name    : String := "Aion") return Operation_Results.Result_Type;

   function Report
     (Runtime : in out Aion.Runtime.Runtime_Handle)
      return String;

   function Report
     (Snapshot : Aion.Metrics.Metrics_Snapshot)
      return String;

   function Image (Status : Health_Status) return String;
   function Image (Health : Runtime_Health) return String;
end Aion.Diagnostics;
