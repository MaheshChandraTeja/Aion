with Ada.Strings.Fixed;

package body Aion.Retry is
   use type Aion.Types.Milliseconds;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function Ms_Image (Value : Aion.Types.Milliseconds) return String is
   begin
      return Aion.Types.Image (Value);
   end Ms_Image;

   function Default return Retry_Config is
   begin
      return Retry_Config'
        (Max_Attempts     => 3,
         Initial_Delay_Ms => 10,
         Max_Delay_Ms     => 5_000,
         Mode             => Exponential_Backoff,
         Retry_Cancelled  => False,
         Retry_Timeouts   => False,
         Retry_Internal   => True,
         Retry_IO         => True);
   end Default;

   function Should_Retry
     (Config  : Retry_Config;
      Attempt : Positive;
      Failure : Aion.Errors.Error) return Boolean
   is
      Code : constant Aion.Errors.Error_Code := Aion.Errors.Code_Of (Failure);
   begin
      if Attempt >= Config.Max_Attempts then
         return False;
      end if;

      case Code is
         when Aion.Errors.Cancelled =>
            return Config.Retry_Cancelled;
         when Aion.Errors.Timeout =>
            return Config.Retry_Timeouts;
         when Aion.Errors.Internal_Error | Aion.Errors.Runtime_Error =>
            return Config.Retry_Internal;
         when Aion.Errors.Io_Error | Aion.Errors.Platform_Error =>
            return Config.Retry_IO;
         when others =>
            return Aion.Errors.Is_Retryable (Code);
      end case;
   end Should_Retry;

   function Delay_For
     (Config  : Retry_Config;
      Attempt : Positive) return Aion.Types.Milliseconds
   is
      Wait_Ms : Aion.Types.Milliseconds := Config.Initial_Delay_Ms;
   begin
      case Config.Mode is
         when No_Backoff =>
            return 0;
         when Fixed_Backoff =>
            Wait_Ms := Config.Initial_Delay_Ms;
         when Exponential_Backoff =>
            Wait_Ms := Config.Initial_Delay_Ms;
            for I in 2 .. Attempt loop
               if Wait_Ms > Config.Max_Delay_Ms / Aion.Types.Milliseconds'(2) then
                  Wait_Ms := Config.Max_Delay_Ms;
                  exit;
               end if;
               Wait_Ms := Wait_Ms * Aion.Types.Milliseconds'(2);
            end loop;
      end case;

      if Wait_Ms > Config.Max_Delay_Ms then
         return Config.Max_Delay_Ms;
      end if;

      return Wait_Ms;
   end Delay_For;

   function Validate
     (Config : Retry_Config) return Operation_Results.Result_Type is
   begin
      if Config.Initial_Delay_Ms > Config.Max_Delay_Ms then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_Argument,
            "initial retry delay cannot exceed max retry delay",
            "Aion.Retry.Validate");
      end if;

      return Operation_Results.Success (True);
   end Validate;

   package body Generic_Retry is
      function Run
        (Config : Retry_Config := Default;
         Token  : Aion.Cancel_Token.Cancel_Token :=
           Aion.Cancel_Token.Null_Token) return Results.Result_Type
      is
         Attempt : Positive := 1;
      begin
         loop
            if Aion.Cancel_Token.Is_Valid (Token) then
               declare
                  C : constant Aion.Cancel_Token.Operation_Results.Result_Type :=
                    Aion.Cancel_Token.Check (Token, "Aion.Retry.Run");
               begin
                  if Aion.Cancel_Token.Operation_Results.Is_Err (C) then
                     return Results.Failure
                       (Aion.Cancel_Token.Operation_Results.Error (C));
                  end if;
               end;
            end if;

            declare
               Result : constant Results.Result_Type := Operation;
            begin
               if Results.Is_Ok (Result) then
                  return Result;
               end if;

               if not Should_Retry (Config, Attempt, Results.Error (Result)) then
                  return Result;
               end if;

               declare
                  Delay_Ms : constant Aion.Types.Milliseconds :=
                    Delay_For (Config, Attempt);
               begin
                  if Delay_Ms > 0 then
                     delay Duration (Long_Float (Delay_Ms) / 1000.0);
                  end if;
               end;

               Attempt := Attempt + 1;
            end;
         end loop;
      end Run;
   end Generic_Retry;

   function Image (Mode : Backoff_Mode) return String is
   begin
      case Mode is
         when No_Backoff =>
            return "no_backoff";
         when Fixed_Backoff =>
            return "fixed_backoff";
         when Exponential_Backoff =>
            return "exponential_backoff";
      end case;
   end Image;

   function Image (Config : Retry_Config) return String is
   begin
      return
        "Retry_Config(max_attempts=" & Trim (Positive'Image (Config.Max_Attempts)) &
        ", initial_delay_ms=" & Ms_Image (Config.Initial_Delay_Ms) &
        ", max_delay_ms=" & Ms_Image (Config.Max_Delay_Ms) &
        ", mode=" & Image (Config.Mode) & ")";
   end Image;

end Aion.Retry;
