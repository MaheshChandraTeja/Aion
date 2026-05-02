with Ada.Text_IO;
with Aion.Errors;
with Aion.Runtime;
with Aion.Task_Group;
with Task_Group_Demo_Jobs;

procedure Task_Group_Demo is
   Runtime : aliased Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Group   : Aion.Task_Group.Task_Group (4);

   Started : Aion.Runtime.Operation_Results.Result_Type;
   Spawned : Aion.Runtime.Spawn_Results.Result_Type;
   Joined  : Aion.Task_Group.Operation_Results.Result_Type;
begin
   Ada.Text_IO.Put_Line ("Aion task group demo");

   Started := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line
        ("Runtime failed to start: " &
         Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (Started)));
      return;
   end if;

   Aion.Task_Group.Initialize
     (Group,
      Runtime'Unchecked_Access,
      "demo-group");

   Spawned := Aion.Task_Group.Spawn
     (Group,
      "demo-work",
      Task_Group_Demo_Jobs.Demo_Work'Access);

   if Aion.Runtime.Spawn_Results.Is_Err (Spawned) then
      Ada.Text_IO.Put_Line
        ("Spawn failed: " &
         Aion.Errors.Image (Aion.Runtime.Spawn_Results.Error (Spawned)));
   end if;

   Joined := Aion.Task_Group.Join_All (Group, Timeout => 2_000);
   if Aion.Task_Group.Operation_Results.Is_Ok (Joined) then
      Ada.Text_IO.Put_Line
        ("Joined group: " &
         Aion.Task_Group.Image (Aion.Task_Group.Stats_Of (Group)));
   else
      Ada.Text_IO.Put_Line
        ("Join failed: " &
         Aion.Errors.Image (Aion.Task_Group.Operation_Results.Error (Joined)));
   end if;

   declare
      Shutdown_Result : constant Aion.Runtime.Operation_Results.Result_Type :=
        Aion.Runtime.Shutdown (Runtime);
   begin
      if Aion.Runtime.Operation_Results.Is_Err (Shutdown_Result) then
         Ada.Text_IO.Put_Line
           ("Runtime shutdown failed: " &
            Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (Shutdown_Result)));
      end if;
   end;
end Task_Group_Demo;
