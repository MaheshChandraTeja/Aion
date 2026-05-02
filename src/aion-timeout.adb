package body Aion.Timeout is

   function Timer
     (Service : not null Aion.Timer_Queue.Timer_Service_Access;
      Within  : Aion.Types.Milliseconds;
      Name    : String := "timeout") return Aion.Timer_Queue.Schedule_Results.Result_Type is
   begin
      return Aion.Timer_Queue.Schedule (Service, Within, Name);
   end Timer;

   package body Generic_Timeout is
      function Await_Within
        (Future : Futures.Future_Handle;
         Within : Aion.Types.Milliseconds) return Futures.Value_Results.Result_Type is
      begin
         return Futures.Await_Timeout (Future, Within);
      end Await_Within;

      function Has_Completed_Within
        (Future : Futures.Future_Handle;
         Within : Aion.Types.Milliseconds) return Boolean is
         Result : constant Futures.Value_Results.Result_Type :=
           Futures.Await_Timeout (Future, Within);
      begin
         return Futures.Value_Results.Is_Ok (Result);
      end Has_Completed_Within;
   end Generic_Timeout;

end Aion.Timeout;
