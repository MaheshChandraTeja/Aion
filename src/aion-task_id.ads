--  Monotonic task identifier generation for Aion runtime tasks.
--  The generator is protected so every worker/runtime operation can allocate
--  task identifiers safely without external locking.

with Aion.Types;

package Aion.Task_Id is
   pragma Preelaborate;

   protected type Generator is
      procedure Reset (Start : Aion.Types.Task_Id := 1);
      procedure Next (Id : out Aion.Types.Task_Id);
      function Peek return Aion.Types.Task_Id;
   private
      Current : Aion.Types.Task_Id := 1;
   end Generator;

   type Generator_Access is access all Generator;

   function Is_Valid (Id : Aion.Types.Task_Id) return Boolean;
   function Image (Id : Aion.Types.Task_Id) return String;

end Aion.Task_Id;
