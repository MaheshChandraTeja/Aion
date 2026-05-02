with Ada.Text_IO;
with Aion.Yield;

package body Aion_Example_Jobs is

   protected Counter is
      procedure Reset;
      procedure Increment;
      function Value return Natural;
   private
      Current : Natural := 0;
   end Counter;

   protected body Counter is
      procedure Reset is
      begin
         Current := 0;
      end Reset;

      procedure Increment is
      begin
         Current := Current + 1;
      end Increment;

      function Value return Natural is
      begin
         return Current;
      end Value;
   end Counter;

   procedure Reset is
   begin
      Counter.Reset;
   end Reset;

   function Count return Natural is
   begin
      return Counter.Value;
   end Count;

   procedure Print_Heartbeat is
   begin
      Ada.Text_IO.Put_Line ("Aion worker executed heartbeat job");
      Aion.Yield.Now;
   end Print_Heartbeat;

   procedure Increment is
   begin
      Counter.Increment;
   end Increment;

   procedure Faulting is
   begin
      raise Program_Error with "example failure isolated by runtime";
   end Faulting;

end Aion_Example_Jobs;
