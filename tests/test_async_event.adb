with Aion.Sync.Event;
with Test_Support;

procedure Test_Async_Event is
   E : Aion.Sync.Event.Async_Event
     (Mode => Aion.Sync.Event.Manual_Reset,
      Initially_Set => False,
      Max_Waiters => 16);
   F : Aion.Sync.Event.Event_Futures.Future_Handle;
   R : Aion.Sync.Event.Event_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Sync.Event");

   F := Aion.Sync.Event.Wait (E);
   Test_Support.Assert
     (Aion.Sync.Event.Event_Futures.Is_Pending (F),
      "event wait should be pending before set");

   Aion.Sync.Event.Set (E);
   R := Aion.Sync.Event.Event_Futures.Await (F);

   Test_Support.Assert
     (Aion.Sync.Event.Event_Futures.Value_Results.Is_Ok (R),
      "event waiter should complete after set");
   Test_Support.Assert (Aion.Sync.Event.Is_Set (E), "manual event remains set");

   Aion.Sync.Event.Reset (E);
   Test_Support.Assert (not Aion.Sync.Event.Is_Set (E), "reset clears manual event");

   Test_Support.Pass ("async event set/reset works");
end Test_Async_Event;
