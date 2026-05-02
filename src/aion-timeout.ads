--  Timeout helpers for futures and runtime timer futures.

with Aion.Future;
with Aion.Timer_Queue;
with Aion.Types;

package Aion.Timeout is

   function Timer
     (Service : not null Aion.Timer_Queue.Timer_Service_Access;
      Within  : Aion.Types.Milliseconds;
      Name    : String := "timeout") return Aion.Timer_Queue.Schedule_Results.Result_Type;

   generic
      with package Futures is new Aion.Future.Generic_Future (<>);
   package Generic_Timeout is
      function Await_Within
        (Future : Futures.Future_Handle;
         Within : Aion.Types.Milliseconds) return Futures.Value_Results.Result_Type;

      function Has_Completed_Within
        (Future : Futures.Future_Handle;
         Within : Aion.Types.Milliseconds) return Boolean;
   end Generic_Timeout;

end Aion.Timeout;
