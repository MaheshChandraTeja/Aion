with Aion.IO_Resource;
with Aion.Reactor;
with Aion.Readiness;
with Aion.Waker;
with Test_Support;

procedure Test_Reactor_Many_Resources is
   Capacity : constant Positive := 128;
   Reactor : Aion.Reactor.Reactor_Service_Access :=
     Aion.Reactor.Create_Service (Max_Resources => Capacity, Max_Events => Capacity);
   Flag : aliased Aion.Waker.Wake_Flag;
   W : constant Aion.Waker.Waker := Aion.Waker.For_Task (3, Flag'Unchecked_Access);
   Registered : Aion.Reactor.Register_Results.Result_Type;
begin
   Test_Support.Section ("reactor many resources");
   Test_Support.Assert
     (Aion.Reactor.Operation_Results.Is_Ok (Aion.Reactor.Start (Reactor)),
      "reactor should start");

   for Index in 1 .. Capacity loop
      Registered := Aion.Reactor.Register
        (Service  => Reactor,
         Handle   => Aion.IO_Resource.Native_Handle (1_000 + Index),
         Interest => Aion.Readiness.Read_Write,
         Waker    => W,
         Name     => "many-resource");
      Test_Support.Assert
        (Aion.Reactor.Register_Results.Is_Ok (Registered),
         "resource registration should succeed under capacity");
   end loop;

   Test_Support.Assert
     (Aion.Reactor.Resource_Count_Of (Reactor.all) = Capacity,
      "reactor should track all registered resources");

   Aion.Reactor.Destroy (Reactor);
   Test_Support.Pass ("registered many resources without queue corruption");
end Test_Reactor_Many_Resources;
