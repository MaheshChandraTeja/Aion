--  Blocking bridge for synchronous Ada code that needs to wait for a Future.
--  This is intentionally explicit so blocking behavior is visible in call sites.

with Aion.Future;
with Aion.Types;

package Aion.Block_On is

   generic
      with package Futures is new Aion.Future.Generic_Future (<>);
   package Generic_Block_On is
      function Run
        (Future : Futures.Future_Handle) return Futures.Value_Results.Result_Type;

      function Run_Timeout
        (Future  : Futures.Future_Handle;
         Timeout : Aion.Types.Milliseconds)
         return Futures.Value_Results.Result_Type;
   end Generic_Block_On;

end Aion.Block_On;
