with Aion.Sync.Condvar;
with Test_Support;

procedure Test_Async_Condvar is
   C : Aion.Sync.Condvar.Async_Condvar (Max_Waiters => 16);
   F : Aion.Sync.Condvar.Wait_Futures.Future_Handle;
   R : Aion.Sync.Condvar.Wait_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Sync.Condvar");

   F := Aion.Sync.Condvar.Wait (C);
   Test_Support.Assert
     (Aion.Sync.Condvar.Wait_Futures.Is_Pending (F),
      "condition variable wait should be pending");

   Aion.Sync.Condvar.Notify_One (C);
   R := Aion.Sync.Condvar.Wait_Futures.Await (F);

   Test_Support.Assert
     (Aion.Sync.Condvar.Wait_Futures.Value_Results.Is_Ok (R),
      "notify_one should wake one waiter");

   Test_Support.Pass ("async condition variable notification works");
end Test_Async_Condvar;
