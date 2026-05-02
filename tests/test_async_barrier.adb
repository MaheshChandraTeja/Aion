with Aion.Sync.Barrier;
with Test_Support;

procedure Test_Async_Barrier is
   B  : Aion.Sync.Barrier.Async_Barrier (Parties => 3, Max_Waiters => 16);
   F1 : Aion.Sync.Barrier.Barrier_Futures.Future_Handle;
   F2 : Aion.Sync.Barrier.Barrier_Futures.Future_Handle;
   F3 : Aion.Sync.Barrier.Barrier_Futures.Future_Handle;
   R1 : Aion.Sync.Barrier.Barrier_Futures.Value_Results.Result_Type;
   R2 : Aion.Sync.Barrier.Barrier_Futures.Value_Results.Result_Type;
   R3 : Aion.Sync.Barrier.Barrier_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Sync.Barrier");

   F1 := Aion.Sync.Barrier.Arrive_And_Wait (B);
   F2 := Aion.Sync.Barrier.Arrive_And_Wait (B);

   Test_Support.Assert
     (Aion.Sync.Barrier.Barrier_Futures.Is_Pending (F1),
      "first barrier arrival should wait");
   Test_Support.Assert
     (Aion.Sync.Barrier.Barrier_Futures.Is_Pending (F2),
      "second barrier arrival should wait");

   F3 := Aion.Sync.Barrier.Arrive_And_Wait (B);

   R1 := Aion.Sync.Barrier.Barrier_Futures.Await (F1);
   R2 := Aion.Sync.Barrier.Barrier_Futures.Await (F2);
   R3 := Aion.Sync.Barrier.Barrier_Futures.Await (F3);

   Test_Support.Assert
     (Aion.Sync.Barrier.Barrier_Futures.Value_Results.Is_Ok (R1) and
      Aion.Sync.Barrier.Barrier_Futures.Value_Results.Is_Ok (R2) and
      Aion.Sync.Barrier.Barrier_Futures.Value_Results.Is_Ok (R3),
      "all barrier arrivals should complete");
   Test_Support.Assert (Aion.Sync.Barrier.Generation_Of (B) = 1, "generation should advance");

   Test_Support.Pass ("async barrier releases one generation");
end Test_Async_Barrier;
