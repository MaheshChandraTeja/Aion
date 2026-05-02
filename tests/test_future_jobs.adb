package body Test_Future_Jobs is

   protected Store is
      procedure Reset;
      procedure Set_Future (F : Int_Futures.Future_Handle);
      procedure Set_Promise (P : Int_Promises.Promise_Handle);
      function Future return Int_Futures.Future_Handle;
      function Promise return Int_Promises.Promise_Handle;
      procedure Set_Awaited (Value : Integer);
      function Awaited return Integer;
   private
      Current_Future  : Int_Futures.Future_Handle := Int_Futures.Null_Future;
      Current_Promise : Int_Promises.Promise_Handle := Int_Promises.Null_Promise;
      Last_Awaited    : Integer := 0;
   end Store;

   protected body Store is
      procedure Reset is
      begin
         Current_Future := Int_Futures.Null_Future;
         Current_Promise := Int_Promises.Null_Promise;
         Last_Awaited := 0;
      end Reset;

      procedure Set_Future (F : Int_Futures.Future_Handle) is
      begin
         Current_Future := F;
      end Set_Future;

      procedure Set_Promise (P : Int_Promises.Promise_Handle) is
      begin
         Current_Promise := P;
      end Set_Promise;

      function Future return Int_Futures.Future_Handle is
      begin
         return Current_Future;
      end Future;

      function Promise return Int_Promises.Promise_Handle is
      begin
         return Current_Promise;
      end Promise;

      procedure Set_Awaited (Value : Integer) is
      begin
         Last_Awaited := Value;
      end Set_Awaited;

      function Awaited return Integer is
      begin
         return Last_Awaited;
      end Awaited;
   end Store;

   procedure Reset is
      P : Int_Promises.Promise_Handle;
      F : Int_Futures.Future_Handle;
   begin
      Store.Reset;
      Int_Promises.New_Promise (P, F, "runtime-propagation");
      Store.Set_Promise (P);
      Store.Set_Future (F);
   end Reset;

   function Future return Int_Futures.Future_Handle is
   begin
      return Store.Future;
   end Future;

   function Awaited_Value return Integer is
   begin
      return Store.Awaited;
   end Awaited_Value;

   procedure Complete_42 is
      Result : Int_Promises.Operation_Results.Result_Type;
   begin
      Result := Int_Promises.Complete (Store.Promise, 42);

      if Int_Promises.Operation_Results.Is_Err (Result) then
         raise Program_Error with "failed to complete test promise";
      end if;
   end Complete_42;

   procedure Await_Then_Double is
      Result : Int_Futures.Value_Results.Result_Type;
   begin
      Result := Int_Futures.Await (Store.Future);

      if Int_Futures.Value_Results.Is_Err (Result) then
         raise Program_Error with "failed to await test future";
      end if;

      Store.Set_Awaited (Int_Futures.Value_Results.Value (Result) * 2);
   end Await_Then_Double;

end Test_Future_Jobs;
