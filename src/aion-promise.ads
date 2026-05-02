--  Generic Promise facade over Aion.Future.
--
--  A promise owns the write side of a future. Completion is one-shot and is
--  enforced by the shared Future state cell. This package deliberately reuses
--  Aion.Future instead of maintaining a second lifecycle model.

with Aion.Errors;
with Aion.Future;

package Aion.Promise is

   generic
      with package Futures is new Aion.Future.Generic_Future (<>);
   package Generic_Promise is
      type Promise_Handle is private;

      Null_Promise : constant Promise_Handle;

      package Operation_Results renames Futures.Operation_Results;

      procedure New_Promise
        (Promise : out Promise_Handle;
         Future  : out Futures.Future_Handle;
         Name    : String := "");

      function Create (Name : String := "") return Promise_Handle;
      function Future_Of (Promise : Promise_Handle) return Futures.Future_Handle;
      function Is_Valid (Promise : Promise_Handle) return Boolean;
      function Is_Done (Promise : Promise_Handle) return Boolean;

      function Complete
        (Promise : Promise_Handle;
         Value   : Futures.Item_Type) return Operation_Results.Result_Type;

      function Fail
        (Promise : Promise_Handle;
         Failure : Aion.Errors.Error) return Operation_Results.Result_Type;

      function Fail
        (Promise : Promise_Handle;
         Code    : Aion.Errors.Error_Code;
         Message : String;
         Origin  : String := "") return Operation_Results.Result_Type;

      function Cancel
        (Promise : Promise_Handle;
         Reason  : String := "promise cancelled") return Operation_Results.Result_Type;

      function Time_Out
        (Promise : Promise_Handle;
         Reason  : String := "promise timed out") return Operation_Results.Result_Type;

      function Image (Promise : Promise_Handle) return String;

   private
      type Promise_Handle is record
         Future : Futures.Future_Handle := Futures.Null_Future;
      end record;

      Null_Promise : constant Promise_Handle :=
        (Future => Futures.Null_Future);
   end Generic_Promise;

end Aion.Promise;
