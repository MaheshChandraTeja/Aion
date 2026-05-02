with Ada.Strings.Fixed;

package body Aion.Cancel is

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function U64_Image (Value : Interfaces.Unsigned_64) return String is
   begin
      return Trim (Interfaces.Unsigned_64'Image (Value));
   end U64_Image;

   function Image (Value : Cancellation_State) return String is
   begin
      case Value is
         when Not_Cancelled =>
            return "not_cancelled";
         when Cancellation_Requested =>
            return "cancellation_requested";
      end case;
   end Image;

   function Image (Value : Failure_Policy) return String is
   begin
      case Value is
         when Continue_On_Failure =>
            return "continue_on_failure";
         when Cancel_Siblings_On_Failure =>
            return "cancel_siblings_on_failure";
         when Stop_Group_On_First_Failure =>
            return "stop_group_on_first_failure";
      end case;
   end Image;

   function Image (Value : Restart_Decision) return String is
   begin
      case Value is
         when Do_Not_Restart =>
            return "do_not_restart";
         when Restart_Immediately =>
            return "restart_immediately";
         when Restart_After_Delay =>
            return "restart_after_delay";
      end case;
   end Image;

   function Image (Stats : Cancellation_Stats) return String is
   begin
      return
        "Cancellation_Stats(created=" & U64_Image (Stats.Created_Tokens) &
        ", requests=" & U64_Image (Stats.Cancel_Requests) &
        ", propagated=" & U64_Image (Stats.Propagated_Requests) &
        ", awaiters=" & U64_Image (Stats.Awaiters_Released) &
        ", deadlines=" & U64_Image (Stats.Deadline_Expirations) & ")";
   end Image;

end Aion.Cancel;
