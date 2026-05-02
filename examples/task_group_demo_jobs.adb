with Ada.Text_IO;

package body Task_Group_Demo_Jobs is
   procedure Demo_Work is
   begin
      Ada.Text_IO.Put_Line ("Hello from a structured Aion task.");
   end Demo_Work;
end Task_Group_Demo_Jobs;
