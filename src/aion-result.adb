package body Aion.Result is

   package body Generic_Result is

      function Success (Value : Value_Type) return Result_Type is
      begin
         return (Status => Successful, Stored_Value => Value);
      end Success;

      function Failure (Failure_Info : Aion.Errors.Error) return Result_Type is
      begin
         return (Status => Failed, Failure_Info => Failure_Info);
      end Failure;

      function Failure
        (Code    : Aion.Errors.Error_Code;
         Message : String;
         Origin  : String := "") return Result_Type is
      begin
         return Failure (Aion.Errors.Make (Code, Message, Origin));
      end Failure;

      function Is_Ok (Item : Result_Type) return Boolean is
      begin
         return Item.Status = Successful;
      end Is_Ok;

      function Is_Err (Item : Result_Type) return Boolean is
      begin
         return Item.Status = Failed;
      end Is_Err;

      function Status_Of (Item : Result_Type) return Result_Status is
      begin
         return Item.Status;
      end Status_Of;

      function Value (Item : Result_Type) return Value_Type is
      begin
         if Item.Status /= Successful then
            raise Invalid_Result_Access with
              "attempted to read value from failed Aion.Result";
         end if;

         return Item.Stored_Value;
      end Value;

      function Error (Item : Result_Type) return Aion.Errors.Error is
      begin
         if Item.Status /= Failed then
            raise Invalid_Result_Access with
              "attempted to read error from successful Aion.Result";
         end if;

         return Item.Failure_Info;
      end Error;

      function Value_Or
        (Item     : Result_Type;
         Fallback : Value_Type) return Value_Type is
      begin
         if Is_Ok (Item) then
            return Item.Stored_Value;
         else
            return Fallback;
         end if;
      end Value_Or;

   end Generic_Result;

end Aion.Result;
