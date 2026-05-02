--  Retry policy helpers for supervised and cancellation-aware work.

with Aion.Cancel_Token;
with Aion.Errors;
with Aion.Result;
with Aion.Types;

package Aion.Retry is

   type Backoff_Mode is
     (No_Backoff,
      Fixed_Backoff,
      Exponential_Backoff);

   type Retry_Config is record
      Max_Attempts       : Positive := 3;
      Initial_Delay_Ms   : Aion.Types.Milliseconds := 10;
      Max_Delay_Ms       : Aion.Types.Milliseconds := 5_000;
      Mode               : Backoff_Mode := Exponential_Backoff;
      Retry_Cancelled    : Boolean := False;
      Retry_Timeouts     : Boolean := False;
      Retry_Internal     : Boolean := True;
      Retry_IO           : Boolean := True;
   end record;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);

   function Default return Retry_Config;

   function Should_Retry
     (Config  : Retry_Config;
      Attempt : Positive;
      Failure : Aion.Errors.Error) return Boolean;

   function Delay_For
     (Config  : Retry_Config;
      Attempt : Positive) return Aion.Types.Milliseconds;

   function Validate
     (Config : Retry_Config) return Operation_Results.Result_Type;

   generic
      type Value_Type is private;
      with package Results is new Aion.Result.Generic_Result (Value_Type);
      with function Operation return Results.Result_Type;
   package Generic_Retry is
      function Run
        (Config : Retry_Config := Default;
         Token  : Aion.Cancel_Token.Cancel_Token :=
           Aion.Cancel_Token.Null_Token) return Results.Result_Type;
   end Generic_Retry;

   function Image (Config : Retry_Config) return String;
   function Image (Mode : Backoff_Mode) return String;

end Aion.Retry;
