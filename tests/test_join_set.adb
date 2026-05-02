with Test_Support;
with Aion.Join_Set;
with Aion.Task_Handle;

procedure Test_Join_Set is
   Set : Aion.Join_Set.Join_Set (4);
   H1  : Aion.Task_Handle.Task_Handle :=
     Aion.Task_Handle.Create (1, "joined-one");
   H2  : Aion.Task_Handle.Task_Handle :=
     Aion.Task_Handle.Create (2, "joined-two");
   R   : Aion.Join_Set.Operation_Results.Result_Type;
   HR  : Aion.Join_Set.Handle_Results.Result_Type;
begin
   Test_Support.Section ("join set");

   Aion.Task_Handle.Mark_Completed (H1);
   Aion.Task_Handle.Mark_Completed (H2);

   R := Aion.Join_Set.Add (Set, H1);
   Test_Support.Assert (Aion.Join_Set.Operation_Results.Is_Ok (R), "add h1");
   R := Aion.Join_Set.Add (Set, H2);
   Test_Support.Assert (Aion.Join_Set.Operation_Results.Is_Ok (R), "add h2");

   HR := Aion.Join_Set.Join_Next (Set, Timeout => 100);
   Test_Support.Assert
     (Aion.Join_Set.Handle_Results.Is_Ok (HR),
      "join next should return a completed handle");

   R := Aion.Join_Set.Join_All (Set, Timeout => 100);
   Test_Support.Assert
     (Aion.Join_Set.Operation_Results.Is_Ok (R),
      "join all should complete");

   Test_Support.Assert
     (Aion.Join_Set.Pending_Of (Set) = 0,
      "no pending handles after join all");

   Test_Support.Pass ("join set tracks and joins task handles");
end Test_Join_Set;
