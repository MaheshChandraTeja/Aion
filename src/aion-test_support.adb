with Ada.Unchecked_Deallocation;

package body Aion.Test_Support is
   use type Interfaces.Unsigned_64;

   procedure Free_Runtime is new Ada.Unchecked_Deallocation
     (Aion.Runtime.Runtime_Handle, Runtime_Access);

   protected body Atomic_Counter is
      procedure Reset is
      begin
         Stored := 0;
      end Reset;

      procedure Increment is
      begin
         Stored := Stored + 1;
      end Increment;

      procedure Add (Amount : Interfaces.Unsigned_64) is
      begin
         Stored := Stored + Amount;
      end Add;

      function Value return Interfaces.Unsigned_64 is
      begin
         return Stored;
      end Value;
   end Atomic_Counter;

   procedure Initialize
     (Harness : in out Runtime_Harness;
      Config  : Aion.Config.Runtime_Config := Aion.Config.Default) is
   begin
      if Harness.Runtime /= null then
         declare
            Result : constant Aion.Runtime.Operation_Results.Result_Type :=
              Aion.Runtime.Shutdown (Harness.Runtime.all);
            pragma Unreferenced (Result);
         begin
            Free_Runtime (Harness.Runtime);
         end;
      end if;

      Harness.Runtime := new Aion.Runtime.Runtime_Handle'(Aion.Runtime.Create (Config));
   end Initialize;

   function Runtime_Of
     (Harness : in out Runtime_Harness) return Runtime_Access is
   begin
      if Harness.Runtime = null then
         Initialize (Harness);
      end if;

      return Harness.Runtime;
   end Runtime_Of;

   function Start
     (Harness : in out Runtime_Harness)
      return Aion.Runtime.Operation_Results.Result_Type is
   begin
      return Aion.Runtime.Start (Runtime_Of (Harness).all);
   end Start;

   function Shutdown
     (Harness : in out Runtime_Harness)
      return Aion.Runtime.Operation_Results.Result_Type is
   begin
      if Harness.Runtime = null then
         return Aion.Runtime.Operation_Results.Success (True);
      end if;

      return Aion.Runtime.Shutdown (Harness.Runtime.all);
   end Shutdown;

   function Spawn
     (Harness : in out Runtime_Harness;
      Name    : String;
      Work    : Aion.Scheduler.Job_Procedure)
      return Aion.Runtime.Spawn_Results.Result_Type is
   begin
      return Aion.Runtime.Spawn (Runtime_Of (Harness).all, Name, Work);
   end Spawn;

   function Spawned_Count
     (Harness : in out Runtime_Harness) return Interfaces.Unsigned_64 is
   begin
      if Harness.Runtime = null then
         return 0;
      end if;

      return Aion.Runtime.Stats_Of (Harness.Runtime.all).Total_Spawned;
   end Spawned_Count;
end Aion.Test_Support;
