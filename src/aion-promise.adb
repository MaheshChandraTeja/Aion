package body Aion.Promise is

   package body Generic_Promise is

      function Invalid_Promise return Aion.Errors.Error is
      begin
         return Aion.Errors.Make
           (Aion.Errors.Invalid_State,
            "promise handle is null or no longer valid",
            "Aion.Promise");
      end Invalid_Promise;

      procedure New_Promise
        (Promise : out Promise_Handle;
         Future  : out Futures.Future_Handle;
         Name    : String := "") is
      begin
         Future := Futures.Create (Name => Name);
         Promise := (Future => Future);
      end New_Promise;

      function Create (Name : String := "") return Promise_Handle is
         Future : Futures.Future_Handle;
      begin
         Future := Futures.Create (Name => Name);
         return (Future => Future);
      end Create;

      function Future_Of (Promise : Promise_Handle) return Futures.Future_Handle is
      begin
         return Promise.Future;
      end Future_Of;

      function Is_Valid (Promise : Promise_Handle) return Boolean is
      begin
         return Futures.Is_Valid (Promise.Future);
      end Is_Valid;

      function Is_Done (Promise : Promise_Handle) return Boolean is
      begin
         return Futures.Is_Done (Promise.Future);
      end Is_Done;

      function Complete
        (Promise : Promise_Handle;
         Value   : Futures.Item_Type) return Operation_Results.Result_Type is
      begin
         if not Is_Valid (Promise) then
            return Operation_Results.Failure (Invalid_Promise);
         end if;

         return Futures.Complete_Success (Promise.Future, Value);
      end Complete;

      function Fail
        (Promise : Promise_Handle;
         Failure : Aion.Errors.Error) return Operation_Results.Result_Type is
      begin
         if not Is_Valid (Promise) then
            return Operation_Results.Failure (Invalid_Promise);
         end if;

         return Futures.Complete_Failure (Promise.Future, Failure);
      end Fail;

      function Fail
        (Promise : Promise_Handle;
         Code    : Aion.Errors.Error_Code;
         Message : String;
         Origin  : String := "") return Operation_Results.Result_Type is
      begin
         return Fail
           (Promise,
            Aion.Errors.Make (Code, Message, Origin));
      end Fail;

      function Cancel
        (Promise : Promise_Handle;
         Reason  : String := "promise cancelled") return Operation_Results.Result_Type is
      begin
         if not Is_Valid (Promise) then
            return Operation_Results.Failure (Invalid_Promise);
         end if;

         return Futures.Complete_Cancelled (Promise.Future, Reason);
      end Cancel;

      function Time_Out
        (Promise : Promise_Handle;
         Reason  : String := "promise timed out") return Operation_Results.Result_Type is
      begin
         if not Is_Valid (Promise) then
            return Operation_Results.Failure (Invalid_Promise);
         end if;

         return Futures.Complete_Timed_Out (Promise.Future, Reason);
      end Time_Out;

      function Image (Promise : Promise_Handle) return String is
      begin
         if not Is_Valid (Promise) then
            return "promise[state=invalid]";
         end if;

         return "promise[" & Futures.Image (Promise.Future) & "]";
      end Image;

   end Generic_Promise;

end Aion.Promise;
