package body Aion.Yield is

   procedure Now is
   begin
      delay 0.0;
   end Now;

   procedure Times (Count : Positive) is
   begin
      for Index in 1 .. Count loop
         pragma Unreferenced (Index);
         Now;
      end loop;
   end Times;

end Aion.Yield;
