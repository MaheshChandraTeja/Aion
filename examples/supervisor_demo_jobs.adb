with Ada.Text_IO;

package body Supervisor_Demo_Jobs is
   procedure Worker is
   begin
      Ada.Text_IO.Put_Line ("Supervised worker ran.");
   end Worker;
end Supervisor_Demo_Jobs;
