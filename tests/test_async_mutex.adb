with Aion.Sync.Mutex;
with Test_Support;

procedure Test_Async_Mutex is
   M  : Aion.Sync.Mutex.Async_Mutex;
   F1 : Aion.Sync.Mutex.Lock_Futures.Future_Handle;
   F2 : Aion.Sync.Mutex.Lock_Futures.Future_Handle;
   R1 : Aion.Sync.Mutex.Lock_Futures.Value_Results.Result_Type;
   R2 : Aion.Sync.Mutex.Lock_Futures.Value_Results.Result_Type;
   G1 : Aion.Sync.Mutex.Lock_Guard;
   G2 : Aion.Sync.Mutex.Lock_Guard;
   Done : Aion.Sync.Boolean_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Sync.Mutex");

   F1 := Aion.Sync.Mutex.Lock (M, Name => "first-lock");
   R1 := Aion.Sync.Mutex.Lock_Futures.Await (F1);
   Test_Support.Assert
     (Aion.Sync.Mutex.Lock_Futures.Value_Results.Is_Ok (R1),
      "first mutex lock should complete immediately");

   G1 := Aion.Sync.Mutex.Lock_Futures.Value_Results.Value (R1);
   Test_Support.Assert (G1.Valid, "first mutex guard should be valid");
   Test_Support.Assert (Aion.Sync.Mutex.Is_Locked (M), "mutex should be locked");

   F2 := Aion.Sync.Mutex.Lock (M, Name => "second-lock");
   Test_Support.Assert
     (Aion.Sync.Mutex.Lock_Futures.Is_Pending (F2),
      "second mutex lock should be pending");
   Test_Support.Assert
     (Aion.Sync.Mutex.Waiter_Count_Of (M) = 1,
      "mutex should track one waiter");

   Done := Aion.Sync.Mutex.Unlock (M, G1);
   Test_Support.Assert
     (Aion.Sync.Boolean_Results.Is_Ok (Done),
      "unlock should transfer ownership");

   R2 := Aion.Sync.Mutex.Lock_Futures.Await (F2);
   Test_Support.Assert
     (Aion.Sync.Mutex.Lock_Futures.Value_Results.Is_Ok (R2),
      "second mutex lock should complete after unlock");

   G2 := Aion.Sync.Mutex.Lock_Futures.Value_Results.Value (R2);
   Done := Aion.Sync.Mutex.Unlock (M, G2);
   Test_Support.Assert (Aion.Sync.Boolean_Results.Is_Ok (Done), "second unlock should pass");
   Test_Support.Assert (not Aion.Sync.Mutex.Is_Locked (M), "mutex should be unlocked");

   Test_Support.Pass ("async mutex ownership transfer works");
end Test_Async_Mutex;
