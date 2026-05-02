--  Completion state model shared by futures, promises, awaitables, and later
--  timeout/cancellation modules. Keep this package small and dependency-light.

package Aion.Completion is
   pragma Preelaborate;

   type Completion_State is
     (Completion_Pending,
      Completion_Ready,
      Completion_Failed,
      Completion_Cancelled,
      Completion_Timed_Out);

   function Image (State : Completion_State) return String;
   function Is_Terminal (State : Completion_State) return Boolean;
   function Is_Success (State : Completion_State) return Boolean;
   function Is_Failure (State : Completion_State) return Boolean;
end Aion.Completion;
