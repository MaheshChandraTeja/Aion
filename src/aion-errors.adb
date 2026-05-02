package body Aion.Errors is

   function Make
     (Code    : Error_Code;
      Message : String;
      Origin  : String := "") return Error is
   begin
      return
        (Code    => Code,
         Message => US.To_Unbounded_String (Message),
         Origin  => US.To_Unbounded_String (Origin));
   end Make;

   function Ok return Error is
   begin
      return Make (None, "", "");
   end Ok;

   function Code_Of (Item : Error) return Error_Code is
   begin
      return Item.Code;
   end Code_Of;

   function Message_Of (Item : Error) return String is
   begin
      return US.To_String (Item.Message);
   end Message_Of;

   function Origin_Of (Item : Error) return String is
   begin
      return US.To_String (Item.Origin);
   end Origin_Of;

   function Has_Error (Item : Error) return Boolean is
   begin
      return Item.Code /= None;
   end Has_Error;

   function Image (Code : Error_Code) return String is
   begin
      case Code is
         when None                => return "none";
         when Invalid_Argument    => return "invalid_argument";
         when Invalid_State       => return "invalid_state";
         when Configuration_Error => return "configuration_error";
         when Runtime_Error       => return "runtime_error";
         when Timeout             => return "timeout";
         when Cancelled           => return "cancelled";
         when Resource_Closed     => return "resource_closed";
         when Not_Implemented     => return "not_implemented";
         when Internal_Error      => return "internal_error";
         when Platform_Error      => return "platform_error";
         when Io_Error            => return "io_error";
         when Permission_Denied   => return "permission_denied";
         when Capacity_Exceeded   => return "capacity_exceeded";
         when Unknown_Error       => return "unknown_error";
      end case;
   end Image;

   function Image (Item : Error) return String is
      Code_Text    : constant String := Image (Item.Code);
      Message_Text : constant String := Message_Of (Item);
      Origin_Text  : constant String := Origin_Of (Item);
   begin
      if Item.Code = None then
         return "ok";
      elsif Origin_Text'Length = 0 then
         return Code_Text & ": " & Message_Text;
      else
         return Code_Text & " at " & Origin_Text & ": " & Message_Text;
      end if;
   end Image;

   function Is_Retryable (Code : Error_Code) return Boolean is
   begin
      case Code is
         when Timeout | Io_Error | Resource_Closed | Platform_Error =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Retryable;

   procedure Raise_If_Error (Item : Error) is
   begin
      if Has_Error (Item) then
         raise Aion_Error with Image (Item);
      end if;
   end Raise_If_Error;

end Aion.Errors;
