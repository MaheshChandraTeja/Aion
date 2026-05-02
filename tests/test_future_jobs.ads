with Aion.Future;
with Aion.Promise;

package Test_Future_Jobs is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);

   procedure Reset;
   function Future return Int_Futures.Future_Handle;
   function Awaited_Value return Integer;

   procedure Complete_42;
   procedure Await_Then_Double;
end Test_Future_Jobs;
