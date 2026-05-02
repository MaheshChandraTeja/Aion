--  Generic poll result abstraction. This is intentionally independent from
--  Future so low-level modules can expose cheap readiness checks without
--  forcing a blocking await path.

with Aion.Errors;

package Aion.Poll is

   type Poll_Status is (Poll_Pending, Poll_Ready, Poll_Failed);

   function Image (Status : Poll_Status) return String;

   generic
      type Value_Type is private;
   package Generic_Poll is
      type Poll_Result (Status : Poll_Status := Poll_Pending) is private;

      function Pending return Poll_Result;
      function Ready (Value : Value_Type) return Poll_Result;
      function Failed (Failure : Aion.Errors.Error) return Poll_Result;
      function Failed
        (Code    : Aion.Errors.Error_Code;
         Message : String;
         Origin  : String := "") return Poll_Result;

      function Is_Pending (Item : Poll_Result) return Boolean;
      function Is_Ready (Item : Poll_Result) return Boolean;
      function Is_Failed (Item : Poll_Result) return Boolean;

      function Value (Item : Poll_Result) return Value_Type;
      function Error (Item : Poll_Result) return Aion.Errors.Error;
   private
      type Poll_Result (Status : Poll_Status := Poll_Pending) is record
         case Status is
            when Poll_Pending =>
               null;
            when Poll_Ready =>
               Stored_Value : Value_Type;
            when Poll_Failed =>
               Failure_Info : Aion.Errors.Error := Aion.Errors.Ok;
         end case;
      end record;
   end Generic_Poll;

end Aion.Poll;
