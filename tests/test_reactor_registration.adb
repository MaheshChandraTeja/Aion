with Aion.IO_Resource;
with Aion.Reactor;
with Aion.Readiness;
with Aion.Waker;
with Test_Support;

procedure Test_Reactor_Registration is
   Reactor : Aion.Reactor.Reactor_Service_Access :=
     Aion.Reactor.Create_Service (Max_Resources => 16, Max_Events => 16);
   Flag : aliased Aion.Waker.Wake_Flag;
   W : constant Aion.Waker.Waker :=
     Aion.Waker.For_Task (1, Flag'Unchecked_Access);
   Registered : Aion.Reactor.Register_Results.Result_Type;
   Resource : Aion.IO_Resource.IO_Resource;
begin
   Test_Support.Section ("reactor registration");
   Test_Support.Assert
     (Aion.Reactor.Operation_Results.Is_Ok (Aion.Reactor.Start (Reactor)),
      "reactor should start");

   Registered := Aion.Reactor.Register
     (Service  => Reactor,
      Handle   => 101,
      Interest => Aion.Readiness.Readable,
      Waker    => W,
      Name     => "registration-test");
   Test_Support.Assert
     (Aion.Reactor.Register_Results.Is_Ok (Registered),
      "reactor registration should succeed");

   Resource := Aion.Reactor.Register_Results.Value (Registered);
   Test_Support.Assert
     (Aion.IO_Resource.Is_Valid (Resource),
      "registered resource should be valid");
   Test_Support.Assert
     (Aion.Reactor.Resource_Count_Of (Reactor.all) = 1,
      "reactor should report one registered resource");

   Test_Support.Assert
     (Aion.Reactor.Operation_Results.Is_Ok (Aion.Reactor.Unregister (Reactor, Resource)),
      "unregister should succeed");
   Test_Support.Assert
     (Aion.Reactor.Resource_Count_Of (Reactor.all) = 0,
      "reactor should report zero resources after unregister");

   Aion.Reactor.Destroy (Reactor);
   Test_Support.Pass (Aion.IO_Resource.Image (Resource));
end Test_Reactor_Registration;
