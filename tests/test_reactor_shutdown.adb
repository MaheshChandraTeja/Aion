with Aion.Reactor;
with Aion.Readiness;
with Aion.Waker;
with Test_Support;

procedure Test_Reactor_Shutdown is
   Reactor : Aion.Reactor.Reactor_Service_Access :=
     Aion.Reactor.Create_Service (Max_Resources => 4, Max_Events => 4);
   Flag : aliased Aion.Waker.Wake_Flag;
   Registered : Aion.Reactor.Register_Results.Result_Type;
   Notify_Result : Aion.Reactor.Operation_Results.Result_Type;
begin
   Test_Support.Section ("reactor shutdown");
   Test_Support.Assert
     (Aion.Reactor.Operation_Results.Is_Ok (Aion.Reactor.Start (Reactor)),
      "reactor should start");

   Registered := Aion.Reactor.Register
     (Service  => Reactor,
      Handle   => 202,
      Interest => Aion.Readiness.Readable,
      Waker    => Aion.Waker.For_Task (2, Flag'Unchecked_Access),
      Name     => "shutdown-test");
   Test_Support.Assert
     (Aion.Reactor.Register_Results.Is_Ok (Registered),
      "registration before shutdown should succeed");

   Aion.Reactor.Stop (Reactor.all);
   delay 0.01;

   Notify_Result := Aion.Reactor.Notify_Readiness
     (Service  => Reactor,
      Resource => Aion.Reactor.Register_Results.Value (Registered),
      Ready    => Aion.Readiness.Readable);
   Test_Support.Assert
     (Aion.Reactor.Operation_Results.Is_Err (Notify_Result),
      "readiness after stop should be rejected");

   Aion.Reactor.Destroy (Reactor);
   Test_Support.Pass ("reactor rejected readiness after shutdown");
end Test_Reactor_Shutdown;
