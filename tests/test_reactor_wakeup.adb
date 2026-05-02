with Aion.IO_Resource;
with Aion.Reactor;
with Aion.Readiness;
with Aion.Waker;
with Test_Support;

procedure Test_Reactor_Wakeup is
   Reactor : Aion.Reactor.Reactor_Service_Access :=
     Aion.Reactor.Create_Service (Max_Resources => 8, Max_Events => 8);
   Flag : aliased Aion.Waker.Wake_Flag;
   W : constant Aion.Waker.Waker := Aion.Waker.For_Task (4, Flag'Unchecked_Access);
   Registered : Aion.Reactor.Register_Results.Result_Type;
   Resource : Aion.IO_Resource.IO_Resource;
   Notify_Result : Aion.Reactor.Operation_Results.Result_Type;
begin
   Test_Support.Section ("reactor wakeup dispatch");
   Test_Support.Assert
     (Aion.Reactor.Operation_Results.Is_Ok (Aion.Reactor.Start (Reactor)),
      "reactor should start");

   Registered := Aion.Reactor.Register
     (Service  => Reactor,
      Handle   => 303,
      Interest => Aion.Readiness.Readable,
      Waker    => W,
      Name     => "wakeup-test");
   Test_Support.Assert
     (Aion.Reactor.Register_Results.Is_Ok (Registered),
      "registration should succeed");

   Resource := Aion.Reactor.Register_Results.Value (Registered);
   Notify_Result := Aion.Reactor.Notify_Readiness
     (Service  => Reactor,
      Resource => Resource,
      Ready    => Aion.Readiness.Readable);
   Test_Support.Assert
     (Aion.Reactor.Operation_Results.Is_Ok (Notify_Result),
      "readiness notification should enqueue");

   delay 0.03;
   Test_Support.Assert (Flag.Is_Awake, "reactor worker should wake the registered waker");
   Test_Support.Assert (Flag.Wake_Count >= 1, "wake count should increase");

   Aion.Reactor.Destroy (Reactor);
   Test_Support.Pass ("reactor dispatched readiness to waker");
end Test_Reactor_Wakeup;
