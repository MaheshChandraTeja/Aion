--  Structured error model for Aion.

with Ada.Strings.Unbounded;

package Aion.Errors is

   type Error_Code is
     (None,
      Invalid_Argument,
      Invalid_State,
      Configuration_Error,
      Runtime_Error,
      Timeout,
      Cancelled,
      Resource_Closed,
      Not_Implemented,
      Internal_Error,
      Platform_Error,
      Io_Error,
      Permission_Denied,
      Capacity_Exceeded,
      Unknown_Error);

   Aion_Error : exception;

   type Error is tagged private;

   function Make
     (Code    : Error_Code;
      Message : String;
      Origin  : String := "") return Error;

   function Ok return Error;

   function Code_Of (Item : Error) return Error_Code;
   function Message_Of (Item : Error) return String;
   function Origin_Of (Item : Error) return String;

   function Has_Error (Item : Error) return Boolean;
   function Image (Code : Error_Code) return String;
   function Image (Item : Error) return String;
   function Is_Retryable (Code : Error_Code) return Boolean;

   procedure Raise_If_Error (Item : Error);

private
   package US renames Ada.Strings.Unbounded;

   type Error is tagged record
      Code    : Error_Code := None;
      Message : US.Unbounded_String := US.Null_Unbounded_String;
      Origin  : US.Unbounded_String := US.Null_Unbounded_String;
   end record;

end Aion.Errors;
