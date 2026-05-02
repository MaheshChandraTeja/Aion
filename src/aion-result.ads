--  Generic success/error result abstraction used by all Aion modules.

with Aion.Errors;

package Aion.Result is

   Invalid_Result_Access : exception;

   type Result_Status is (Successful, Failed);

   generic
      type Value_Type is private;
   package Generic_Result is
      type Result_Type is private;

      function Success (Value : Value_Type) return Result_Type;

      function Failure (Failure_Info : Aion.Errors.Error) return Result_Type;

      function Failure
        (Code    : Aion.Errors.Error_Code;
         Message : String;
         Origin  : String := "") return Result_Type;

      function Is_Ok (Item : Result_Type) return Boolean;
      function Is_Err (Item : Result_Type) return Boolean;
      function Status_Of (Item : Result_Type) return Result_Status;

      function Value (Item : Result_Type) return Value_Type;
      function Error (Item : Result_Type) return Aion.Errors.Error;

      function Value_Or
        (Item     : Result_Type;
         Fallback : Value_Type) return Value_Type;

   private
      type Result_Type (Status : Result_Status := Failed) is record
         case Status is
            when Successful =>
               Stored_Value : Value_Type;
            when Failed =>
               Failure_Info : Aion.Errors.Error := Aion.Errors.Ok;
         end case;
      end record;
   end Generic_Result;

end Aion.Result;
