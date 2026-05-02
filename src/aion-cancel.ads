--  Cancellation parent package for Aion.
--
--  This package centralizes cancellation-related shared types so task groups,
--  scopes, supervisors, retry policies, futures, channels, timers, and runtime
--  shutdown code reuse one vocabulary.

with Interfaces;
with Aion.Future;
with Aion.Result;

package Aion.Cancel is
   pragma Elaborate_Body;

   type Cancellation_State is
     (Not_Cancelled,
      Cancellation_Requested);

   type Failure_Policy is
     (Continue_On_Failure,
      Cancel_Siblings_On_Failure,
      Stop_Group_On_First_Failure);

   type Restart_Decision is
     (Do_Not_Restart,
      Restart_Immediately,
      Restart_After_Delay);

   type Cancellation_Stats is record
      Created_Tokens       : Interfaces.Unsigned_64 := 0;
      Cancel_Requests      : Interfaces.Unsigned_64 := 0;
      Propagated_Requests  : Interfaces.Unsigned_64 := 0;
      Awaiters_Released    : Interfaces.Unsigned_64 := 0;
      Deadline_Expirations : Interfaces.Unsigned_64 := 0;
   end record;

   package Boolean_Futures is new Aion.Future.Generic_Future (Boolean);
   package Boolean_Results is new Aion.Result.Generic_Result (Boolean);

   function Image (Value : Cancellation_State) return String;
   function Image (Value : Failure_Policy) return String;
   function Image (Value : Restart_Decision) return String;
   function Image (Stats : Cancellation_Stats) return String;


end Aion.Cancel;
