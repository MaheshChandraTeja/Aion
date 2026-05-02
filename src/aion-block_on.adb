package body Aion.Block_On is

   package body Generic_Block_On is

      function Run
        (Future : Futures.Future_Handle) return Futures.Value_Results.Result_Type is
      begin
         return Futures.Await (Future);
      end Run;

      function Run_Timeout
        (Future  : Futures.Future_Handle;
         Timeout : Aion.Types.Milliseconds)
         return Futures.Value_Results.Result_Type is
      begin
         return Futures.Await_Timeout (Future, Timeout);
      end Run_Timeout;

   end Generic_Block_On;

end Aion.Block_On;
