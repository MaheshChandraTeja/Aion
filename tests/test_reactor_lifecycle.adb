with Aion.Reactor;
with Test_Support;

procedure Test_Reactor_Lifecycle is
   use type Aion.Reactor.Reactor_Service_Access;
   Reactor : Aion.Reactor.Reactor_Service_Access :=
     Aion.Reactor.Create_Service (Max_Resources => 8, Max_Events => 8);
   Start_Result : Aion.Reactor.Operation_Results.Result_Type;
   Stats : Aion.Reactor.Reactor_Stats;
begin
   Test_Support.Section ("reactor lifecycle");
   Start_Result := Aion.Reactor.Start (Reactor);
   Test_Support.Assert
     (Aion.Reactor.Operation_Results.Is_Ok (Start_Result),
      "reactor should start successfully");

   delay 0.01;
   Stats := Aion.Reactor.Stats_Of (Reactor.all);
   Test_Support.Assert (Stats.Worker_Running, "reactor worker should be running after start");

   Aion.Reactor.Stop (Reactor.all);
   Aion.Reactor.Destroy (Reactor);
   Test_Support.Assert (Reactor = null, "destroy should null the reactor access value");
   Test_Support.Pass ("reactor lifecycle completed");
end Test_Reactor_Lifecycle;
