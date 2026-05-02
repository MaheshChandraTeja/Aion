with Aion.Future;
with Aion.Promise;

package Runtime_Future_Demo_Jobs is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);

   procedure Reset;
   function Future return Int_Futures.Future_Handle;
   procedure Complete_From_Runtime;
end Runtime_Future_Demo_Jobs;
