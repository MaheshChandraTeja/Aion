with Aion.Sync.Semaphore;
with Test_Support;

procedure Test_Async_Semaphore is
   S  : Aion.Sync.Semaphore.Async_Semaphore
     (Initial_Permits => 1, Maximum_Permits => 1, Max_Waiters => 16);
   F1 : Aion.Sync.Semaphore.Permit_Futures.Future_Handle;
   F2 : Aion.Sync.Semaphore.Permit_Futures.Future_Handle;
   R1 : Aion.Sync.Semaphore.Permit_Futures.Value_Results.Result_Type;
   R2 : Aion.Sync.Semaphore.Permit_Futures.Value_Results.Result_Type;
   P1 : Aion.Sync.Semaphore.Permit_Guard;
   P2 : Aion.Sync.Semaphore.Permit_Guard;
   Done : Aion.Sync.Boolean_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Sync.Semaphore");

   F1 := Aion.Sync.Semaphore.Acquire (S);
   R1 := Aion.Sync.Semaphore.Permit_Futures.Await (F1);
   Test_Support.Assert
     (Aion.Sync.Semaphore.Permit_Futures.Value_Results.Is_Ok (R1),
      "first semaphore acquire should complete immediately");
   P1 := Aion.Sync.Semaphore.Permit_Futures.Value_Results.Value (R1);

   F2 := Aion.Sync.Semaphore.Acquire (S);
   Test_Support.Assert
     (Aion.Sync.Semaphore.Permit_Futures.Is_Pending (F2),
      "second semaphore acquire should wait");
   Test_Support.Assert
     (Aion.Sync.Semaphore.Waiter_Count_Of (S) = 1,
      "semaphore should track one waiter");

   Done := Aion.Sync.Semaphore.Release (S, P1);
   Test_Support.Assert (Aion.Sync.Boolean_Results.Is_Ok (Done), "release should pass");

   R2 := Aion.Sync.Semaphore.Permit_Futures.Await (F2);
   Test_Support.Assert
     (Aion.Sync.Semaphore.Permit_Futures.Value_Results.Is_Ok (R2),
      "second acquire should complete after release");
   P2 := Aion.Sync.Semaphore.Permit_Futures.Value_Results.Value (R2);

   Done := Aion.Sync.Semaphore.Release (S, P2);
   Test_Support.Assert (Aion.Sync.Boolean_Results.Is_Ok (Done), "second release should pass");
   Test_Support.Assert (Aion.Sync.Semaphore.Available_Of (S) = 1, "permit should return");

   Test_Support.Pass ("async semaphore backpressure works");
end Test_Async_Semaphore;
