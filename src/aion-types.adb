with Ada.Strings.Fixed;

package body Aion.Types is

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function Image (Value : Runtime_State) return String is
   begin
      case Value is
         when Runtime_Created      => return "created";
         when Runtime_Initializing => return "initializing";
         when Runtime_Running      => return "running";
         when Runtime_Stopping     => return "stopping";
         when Runtime_Stopped      => return "stopped";
         when Runtime_Failed       => return "failed";
      end case;
   end Image;

   function Image (Value : Task_State) return String is
   begin
      case Value is
         when Task_Pending   => return "pending";
         when Task_Scheduled => return "scheduled";
         when Task_Running   => return "running";
         when Task_Completed => return "completed";
         when Task_Cancelled => return "cancelled";
         when Task_Faulted   => return "faulted";
      end case;
   end Image;

   function Image (Value : Shutdown_Mode) return String is
   begin
      case Value is
         when Shutdown_Graceful  => return "graceful";
         when Shutdown_Immediate => return "immediate";
      end case;
   end Image;

   function Image (Value : Log_Level) return String is
   begin
      case Value is
         when Log_Trace => return "trace";
         when Log_Debug => return "debug";
         when Log_Info  => return "info";
         when Log_Warn  => return "warn";
         when Log_Error => return "error";
         when Log_Off   => return "off";
      end case;
   end Image;

   function Image (Value : Resource_State) return String is
   begin
      case Value is
         when Resource_Open    => return "open";
         when Resource_Closing => return "closing";
         when Resource_Closed  => return "closed";
      end case;
   end Image;

   function Image (Value : Milliseconds) return String is
   begin
      return Trim (Milliseconds'Image (Value)) & "ms";
   end Image;

   function Image (Value : Task_Id) return String is
   begin
      return Trim (Task_Id'Image (Value));
   end Image;

   function Is_Terminal (Value : Task_State) return Boolean is
   begin
      return Value in Task_Completed | Task_Cancelled | Task_Faulted;
   end Is_Terminal;

   function Is_Running (Value : Runtime_State) return Boolean is
   begin
      return Value = Runtime_Running;
   end Is_Running;

end Aion.Types;
