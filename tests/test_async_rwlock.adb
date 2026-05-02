with Aion.Sync.RWLock;
with Test_Support;

procedure Test_Async_RWLock is
   L  : Aion.Sync.RWLock.Async_RWLock (Max_Waiters => 16);
   RF1 : Aion.Sync.RWLock.Guard_Futures.Future_Handle;
   RF2 : Aion.Sync.RWLock.Guard_Futures.Future_Handle;
   WF  : Aion.Sync.RWLock.Guard_Futures.Future_Handle;
   RR1 : Aion.Sync.RWLock.Guard_Futures.Value_Results.Result_Type;
   RR2 : Aion.Sync.RWLock.Guard_Futures.Value_Results.Result_Type;
   WR  : Aion.Sync.RWLock.Guard_Futures.Value_Results.Result_Type;
   RG1 : Aion.Sync.RWLock.RW_Guard;
   RG2 : Aion.Sync.RWLock.RW_Guard;
   WG  : Aion.Sync.RWLock.RW_Guard;
   Done : Aion.Sync.Boolean_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Sync.RWLock");

   RF1 := Aion.Sync.RWLock.Read_Lock (L);
   RF2 := Aion.Sync.RWLock.Read_Lock (L);
   RR1 := Aion.Sync.RWLock.Guard_Futures.Await (RF1);
   RR2 := Aion.Sync.RWLock.Guard_Futures.Await (RF2);

   Test_Support.Assert
     (Aion.Sync.RWLock.Guard_Futures.Value_Results.Is_Ok (RR1) and
      Aion.Sync.RWLock.Guard_Futures.Value_Results.Is_Ok (RR2),
      "multiple readers should acquire");
   RG1 := Aion.Sync.RWLock.Guard_Futures.Value_Results.Value (RR1);
   RG2 := Aion.Sync.RWLock.Guard_Futures.Value_Results.Value (RR2);

   WF := Aion.Sync.RWLock.Write_Lock (L);
   Test_Support.Assert
     (Aion.Sync.RWLock.Guard_Futures.Is_Pending (WF),
      "writer should wait for readers");

   Done := Aion.Sync.RWLock.Unlock (L, RG1);
   Test_Support.Assert (Aion.Sync.Boolean_Results.Is_Ok (Done), "first read unlock should pass");
   Test_Support.Assert
     (Aion.Sync.RWLock.Guard_Futures.Is_Pending (WF),
      "writer remains pending while one reader remains");

   Done := Aion.Sync.RWLock.Unlock (L, RG2);
   Test_Support.Assert (Aion.Sync.Boolean_Results.Is_Ok (Done), "second read unlock should pass");

   WR := Aion.Sync.RWLock.Guard_Futures.Await (WF);
   Test_Support.Assert
     (Aion.Sync.RWLock.Guard_Futures.Value_Results.Is_Ok (WR),
      "writer should acquire after readers release");
   WG := Aion.Sync.RWLock.Guard_Futures.Value_Results.Value (WR);

   Done := Aion.Sync.RWLock.Unlock (L, WG);
   Test_Support.Assert (Aion.Sync.Boolean_Results.Is_Ok (Done), "writer unlock should pass");
   Test_Support.Assert (not Aion.Sync.RWLock.Has_Writer (L), "writer should be released");

   Test_Support.Pass ("async rwlock reader/writer coordination works");
end Test_Async_RWLock;
