with Aion.Completion;
with Aion.Sync.Mutex;
with Test_Support;

procedure Test_Sync_Cancellation is
   use type Aion.Completion.Completion_State;
   M : Aion.Sync.Mutex.Async_Mutex (Max_Waiters => 16);
   F1 : Aion.Sync.Mutex.Lock_Futures.Future_Handle;
   F2 : Aion.Sync.Mutex.Lock_Futures.Future_Handle;
   R1 : Aion.Sync.Mutex.Lock_Futures.Value_Results.Result_Type;
   G1 : Aion.Sync.Mutex.Lock_Guard;
   Done : Aion.Sync.Boolean_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Sync cancellation hooks");

   F1 := Aion.Sync.Mutex.Lock (M);
   R1 := Aion.Sync.Mutex.Lock_Futures.Await (F1);
   G1 := Aion.Sync.Mutex.Lock_Futures.Value_Results.Value (R1);

   F2 := Aion.Sync.Mutex.Lock (M);
   Test_Support.Assert
     (Aion.Sync.Mutex.Lock_Futures.Is_Pending (F2),
      "second mutex waiter should be pending before cancellation");

   Done := Aion.Sync.Mutex.Cancel_Waiter (M, F2, "test cancellation");
   Test_Support.Assert
     (Aion.Sync.Boolean_Results.Is_Ok (Done),
      "queued mutex waiter cancellation should pass");
   Test_Support.Assert
     (Aion.Sync.Mutex.Lock_Futures.State_Of (F2) = Aion.Completion.Completion_Cancelled,
      "future state should become cancelled");

   Done := Aion.Sync.Mutex.Unlock (M, G1);
   Test_Support.Assert (Aion.Sync.Boolean_Results.Is_Ok (Done), "cleanup unlock should pass");

   Test_Support.Pass ("queued sync waiter cancellation works");
end Test_Sync_Cancellation;
