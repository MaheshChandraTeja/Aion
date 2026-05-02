with Ada.Text_IO;
with Aion.Sync.Mutex;
with Aion.Sync.Semaphore;
with Aion.Sync.Event;
with Aion.Sync.Once;

procedure Sync_Primitives_Demo is
   Mutex : Aion.Sync.Mutex.Async_Mutex;
   Lock_Future : Aion.Sync.Mutex.Lock_Futures.Future_Handle;
   Lock_Result : Aion.Sync.Mutex.Lock_Futures.Value_Results.Result_Type;
   Guard : Aion.Sync.Mutex.Lock_Guard;
   Done : Aion.Sync.Boolean_Results.Result_Type;

   Semaphore : Aion.Sync.Semaphore.Async_Semaphore
     (Initial_Permits => 2, Maximum_Permits => 2, Max_Waiters => 32);

   Event : Aion.Sync.Event.Async_Event
     (Mode => Aion.Sync.Event.Manual_Reset,
      Initially_Set => False,
      Max_Waiters => 32);

   package Integer_Once is new Aion.Sync.Once.Generic_Once (Integer);
   Cell : Integer_Once.Once_Cell;
begin
   Ada.Text_IO.Put_Line ("Aion sync primitives demo");

   Lock_Future := Aion.Sync.Mutex.Lock (Mutex);
   Lock_Result := Aion.Sync.Mutex.Lock_Futures.Await (Lock_Future);

   if Aion.Sync.Mutex.Lock_Futures.Value_Results.Is_Ok (Lock_Result) then
      Guard := Aion.Sync.Mutex.Lock_Futures.Value_Results.Value (Lock_Result);
      Ada.Text_IO.Put_Line ("mutex acquired");
      Done := Aion.Sync.Mutex.Unlock (Mutex, Guard);
      if Aion.Sync.Boolean_Results.Is_Ok (Done) then
         Ada.Text_IO.Put_Line ("mutex released");
      end if;
   end if;

   declare
      Permit_Future : constant Aion.Sync.Semaphore.Permit_Futures.Future_Handle :=
        Aion.Sync.Semaphore.Acquire (Semaphore);
      Permit_Result : constant Aion.Sync.Semaphore.Permit_Futures.Value_Results.Result_Type :=
        Aion.Sync.Semaphore.Permit_Futures.Await (Permit_Future);
      Permit : Aion.Sync.Semaphore.Permit_Guard;
   begin
      if Aion.Sync.Semaphore.Permit_Futures.Value_Results.Is_Ok (Permit_Result) then
         Permit := Aion.Sync.Semaphore.Permit_Futures.Value_Results.Value (Permit_Result);
         Ada.Text_IO.Put_Line ("semaphore permit acquired");
         Done := Aion.Sync.Semaphore.Release (Semaphore, Permit);
      end if;
   end;

   declare
      Event_Future : constant Aion.Sync.Event.Event_Futures.Future_Handle :=
        Aion.Sync.Event.Wait (Event);
      Event_Result : Aion.Sync.Event.Event_Futures.Value_Results.Result_Type;
   begin
      Aion.Sync.Event.Set (Event);
      Event_Result := Aion.Sync.Event.Event_Futures.Await (Event_Future);
      if Aion.Sync.Event.Event_Futures.Value_Results.Is_Ok (Event_Result) then
         Ada.Text_IO.Put_Line ("event waiter completed");
      end if;
   end;

   Done := Integer_Once.Set (Cell, 2026);
   if Aion.Sync.Boolean_Results.Is_Ok (Done) then
      Ada.Text_IO.Put_Line ("once cell initialized");
   end if;

   Ada.Text_IO.Put_Line ("sync primitives demo finished");
end Sync_Primitives_Demo;
