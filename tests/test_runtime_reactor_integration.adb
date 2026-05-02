with Aion.Config;
with Aion.Reactor;
with Aion.Runtime;
with Test_Support;

procedure Test_Runtime_Reactor_Integration is
   use type Aion.Reactor.Reactor_Service_Access;
   Config : constant Aion.Config.Runtime_Config :=
     Aion.Config.With_Max_Queue_Depth (Aion.Config.Default, 64);
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create (Config);
   Start_Result : Aion.Runtime.Operation_Results.Result_Type;
   Reactor : Aion.Reactor.Reactor_Service_Access;
   Stats : Aion.Runtime.Runtime_Stats;
begin
   Test_Support.Section ("runtime reactor integration");
   Start_Result := Aion.Runtime.Start (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Start_Result),
      "runtime should start with reactor service");

   Reactor := Aion.Runtime.Reactor_Of (Runtime);
   Test_Support.Assert (Reactor /= null, "runtime should own a reactor service");
   Test_Support.Assert
     (Aion.Reactor.Stats_Of (Reactor.all).Worker_Running,
      "runtime start should start reactor worker");

   Stats := Aion.Runtime.Stats_Of (Runtime);
   Test_Support.Assert
     (Stats.Reactor_Resources = 0,
      "fresh runtime reactor should have no resources");

   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Aion.Runtime.Shutdown (Runtime)),
      "runtime shutdown should stop reactor service");
   Test_Support.Pass (Aion.Runtime.Image (Stats));
end Test_Runtime_Reactor_Integration;
