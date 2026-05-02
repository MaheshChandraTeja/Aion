package body Runtime_Future_Demo_Jobs is

   protected Store is
      procedure Reset;
      function Future return Int_Futures.Future_Handle;
      function Promise return Int_Promises.Promise_Handle;
   private
      P : Int_Promises.Promise_Handle := Int_Promises.Null_Promise;
      F : Int_Futures.Future_Handle := Int_Futures.Null_Future;
   end Store;

   protected body Store is
      procedure Reset is
      begin
         Int_Promises.New_Promise (P, F, "runtime-demo-future");
      end Reset;

      function Future return Int_Futures.Future_Handle is
      begin
         return F;
      end Future;

      function Promise return Int_Promises.Promise_Handle is
      begin
         return P;
      end Promise;
   end Store;

   procedure Reset is
   begin
      Store.Reset;
   end Reset;

   function Future return Int_Futures.Future_Handle is
   begin
      return Store.Future;
   end Future;

   procedure Complete_From_Runtime is
      Result : Int_Promises.Operation_Results.Result_Type;
   begin
      Result := Int_Promises.Complete (Store.Promise, 8080);

      if Int_Promises.Operation_Results.Is_Err (Result) then
         raise Program_Error with "failed to complete runtime demo future";
      end if;
   end Complete_From_Runtime;

end Runtime_Future_Demo_Jobs;
