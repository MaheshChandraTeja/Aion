package body Aion.Completion is

   function Image (State : Completion_State) return String is
   begin
      case State is
         when Completion_Pending   => return "pending";
         when Completion_Ready     => return "ready";
         when Completion_Failed    => return "failed";
         when Completion_Cancelled => return "cancelled";
         when Completion_Timed_Out => return "timed-out";
      end case;
   end Image;

   function Is_Terminal (State : Completion_State) return Boolean is
   begin
      return State /= Completion_Pending;
   end Is_Terminal;

   function Is_Success (State : Completion_State) return Boolean is
   begin
      return State = Completion_Ready;
   end Is_Success;

   function Is_Failure (State : Completion_State) return Boolean is
   begin
      return State in Completion_Failed | Completion_Cancelled | Completion_Timed_Out;
   end Is_Failure;

end Aion.Completion;
