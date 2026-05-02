with Ada.Text_IO;
with Aion.Errors;
with Aion.Runtime;
with Aion.Supervisor;
with Supervisor_Demo_Jobs;

procedure Supervisor_Demo is
   Runtime : aliased Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Sup     : Aion.Supervisor.Supervisor (2);

   R : Aion.Runtime.Operation_Results.Result_Type;
   S : Aion.Runtime.Spawn_Results.Result_Type;
begin
   Ada.Text_IO.Put_Line ("Aion supervisor demo");

   R := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (R) then
      Ada.Text_IO.Put_Line
        ("Runtime start failed: " &
         Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (R)));
      return;
   end if;

   Aion.Supervisor.Initialize
     (Sup,
      Runtime'Unchecked_Access,
      "demo-supervisor",
      Config =>
        (Policy           => Aion.Supervisor.Restart_Failed_Children,
         Max_Restarts     => 2,
         Restart_Delay_Ms => 10,
         Join_Timeout_Ms  => 1_000));

   S := Aion.Supervisor.Spawn
     (Sup,
      "worker",
      Supervisor_Demo_Jobs.Worker'Access);

   if Aion.Runtime.Spawn_Results.Is_Ok (S) then
      delay 0.050;
      Ada.Text_IO.Put_Line
        ("Supervisor stats: " &
         Aion.Supervisor.Image (Aion.Supervisor.Stats_Of (Sup)));
   else
      Ada.Text_IO.Put_Line
        ("Supervisor spawn failed: " &
         Aion.Errors.Image (Aion.Runtime.Spawn_Results.Error (S)));
   end if;

   R := Aion.Runtime.Shutdown (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (R) then
      Ada.Text_IO.Put_Line
        ("Runtime shutdown failed: " &
         Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (R)));
   end if;
end Supervisor_Demo;
