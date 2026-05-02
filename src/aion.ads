--  Aion Async Runtime
--  Core public package. Child packages provide runtime, scheduler, shared
--  types, configuration, results, errors, and task primitives.

package Aion is
   pragma Preelaborate;
   Library_Name : constant String := "Aion";

   function Name return String;
   function Description return String;

   procedure Initialize;
   procedure Finalize;
   function Is_Initialized return Boolean;
end Aion;
