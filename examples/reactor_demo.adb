with Ada.Text_IO;
with Aion.Config;
with Aion.IO_Resource;
with Aion.Reactor;
with Aion.Readiness;
with Aion.Runtime;
with Aion.Waker;

procedure Reactor_Demo is
   Config : constant Aion.Config.Runtime_Config :=
     Aion.Config.With_Max_Queue_Depth (Aion.Config.Default, 128);
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create (Config);
   Reactor : Aion.Reactor.Reactor_Service_Access;
   Flag : aliased Aion.Waker.Wake_Flag;
   Registered : Aion.Reactor.Register_Results.Result_Type;
   Resource : Aion.IO_Resource.IO_Resource;
begin
   Ada.Text_IO.Put_Line ("Aion Reactor Demo");

   if Aion.Runtime.Operation_Results.Is_Err (Aion.Runtime.Start (Runtime)) then
      Ada.Text_IO.Put_Line ("runtime failed to start");
      return;
   end if;

   Reactor := Aion.Runtime.Reactor_Of (Runtime);

   Registered := Aion.Reactor.Register
     (Service  => Reactor,
      Handle   => 42,
      Interest => Aion.Readiness.Readable,
      Waker    => Aion.Waker.For_Task (42, Flag'Unchecked_Access),
      Name     => "demo-resource");

   if Aion.Reactor.Register_Results.Is_Err (Registered) then
      Ada.Text_IO.Put_Line ("registration failed");
      return;
   end if;

   Resource := Aion.Reactor.Register_Results.Value (Registered);
   Ada.Text_IO.Put_Line ("registered " & Aion.IO_Resource.Image (Resource));

   if Aion.Reactor.Operation_Results.Is_Ok
     (Aion.Reactor.Notify_Readiness
        (Service  => Reactor,
         Resource => Resource,
         Ready    => Aion.Readiness.Readable))
   then
      Ada.Text_IO.Put_Line ("readiness queued");
   end if;

   delay 0.05;

   if Flag.Is_Awake then
      Ada.Text_IO.Put_Line ("waker fired from reactor worker");
   else
      Ada.Text_IO.Put_Line ("waker did not fire");
   end if;

   Ada.Text_IO.Put_Line (Aion.Reactor.Image (Aion.Reactor.Stats_Of (Reactor.all)));

   declare
      Shutdown_Result : constant Aion.Runtime.Operation_Results.Result_Type :=
        Aion.Runtime.Shutdown (Runtime);
   begin
      if Aion.Runtime.Operation_Results.Is_Err (Shutdown_Result) then
         Ada.Text_IO.Put_Line ("runtime shutdown failed");
      end if;
   end;
end Reactor_Demo;
