package body Aion.Poll is

   function Image (Status : Poll_Status) return String is
   begin
      case Status is
         when Poll_Pending => return "pending";
         when Poll_Ready   => return "ready";
         when Poll_Failed  => return "failed";
      end case;
   end Image;

   package body Generic_Poll is

      function Pending return Poll_Result is
      begin
         return (Status => Poll_Pending);
      end Pending;

      function Ready (Value : Value_Type) return Poll_Result is
      begin
         return (Status => Poll_Ready, Stored_Value => Value);
      end Ready;

      function Failed (Failure : Aion.Errors.Error) return Poll_Result is
      begin
         return (Status => Poll_Failed, Failure_Info => Failure);
      end Failed;

      function Failed
        (Code    : Aion.Errors.Error_Code;
         Message : String;
         Origin  : String := "") return Poll_Result is
      begin
         return Failed (Aion.Errors.Make (Code, Message, Origin));
      end Failed;

      function Is_Pending (Item : Poll_Result) return Boolean is
      begin
         return Item.Status = Poll_Pending;
      end Is_Pending;

      function Is_Ready (Item : Poll_Result) return Boolean is
      begin
         return Item.Status = Poll_Ready;
      end Is_Ready;

      function Is_Failed (Item : Poll_Result) return Boolean is
      begin
         return Item.Status = Poll_Failed;
      end Is_Failed;

      function Value (Item : Poll_Result) return Value_Type is
      begin
         if Item.Status /= Poll_Ready then
            raise Aion.Errors.Aion_Error with
              "poll result does not contain a ready value";
         end if;

         return Item.Stored_Value;
      end Value;

      function Error (Item : Poll_Result) return Aion.Errors.Error is
      begin
         if Item.Status = Poll_Failed then
            return Item.Failure_Info;
         end if;

         return Aion.Errors.Ok;
      end Error;

   end Generic_Poll;

end Aion.Poll;
