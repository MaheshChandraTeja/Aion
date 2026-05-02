with Interfaces;
with Aion.Sync;
with Aion.Sync.Mutex;
with Test_Support;

procedure Test_Sync_Stress is
   use type Interfaces.Unsigned_64;

   Counter : Aion.Sync.Atomic_Counter;
   M       : Aion.Sync.Mutex.Async_Mutex (Max_Waiters => 64);
   F       : Aion.Sync.Mutex.Lock_Futures.Future_Handle;
   R       : Aion.Sync.Mutex.Lock_Futures.Value_Results.Result_Type;
   G       : Aion.Sync.Mutex.Lock_Guard;
   Done    : Aion.Sync.Boolean_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Sync stress");

   for I in 1 .. 1_000 loop
      Counter.Increment;
   end loop;
   Test_Support.Assert (Counter.Value = 1_000, "atomic counter should count stress loop");

   for I in 1 .. 250 loop
      F := Aion.Sync.Mutex.Lock (M);
      R := Aion.Sync.Mutex.Lock_Futures.Await (F);
      Test_Support.Assert
        (Aion.Sync.Mutex.Lock_Futures.Value_Results.Is_Ok (R),
         "stress mutex acquire should pass");
      G := Aion.Sync.Mutex.Lock_Futures.Value_Results.Value (R);
      Done := Aion.Sync.Mutex.Unlock (M, G);
      Test_Support.Assert
        (Aion.Sync.Boolean_Results.Is_Ok (Done),
         "stress mutex release should pass");
   end loop;

   Test_Support.Assert
     (Aion.Sync.Mutex.Stats_Of (M).Acquisitions >= 250,
      "mutex should record stress acquisitions");

   Test_Support.Pass ("sync primitives tolerate repeated lightweight operations");
end Test_Sync_Stress;
