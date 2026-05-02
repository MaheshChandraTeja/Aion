with Ada.Calendar;
with Ada.Text_IO;
with Aion.Sync.Mutex;

procedure Bench_Sync is
   Iterations : constant Positive := 10_000;
   M : Aion.Sync.Mutex.Async_Mutex (Max_Waiters => 64);
   Start_Time : Ada.Calendar.Time;
   Stop_Time  : Ada.Calendar.Time;
   F : Aion.Sync.Mutex.Lock_Futures.Future_Handle;
   R : Aion.Sync.Mutex.Lock_Futures.Value_Results.Result_Type;
   G : Aion.Sync.Mutex.Lock_Guard;
   Done : Aion.Sync.Boolean_Results.Result_Type;
begin
   Ada.Text_IO.Put_Line ("Aion sync benchmark: mutex acquire/release");

   Start_Time := Ada.Calendar.Clock;
   for I in 1 .. Iterations loop
      F := Aion.Sync.Mutex.Lock (M);
      R := Aion.Sync.Mutex.Lock_Futures.Await (F);
      G := Aion.Sync.Mutex.Lock_Futures.Value_Results.Value (R);
      Done := Aion.Sync.Mutex.Unlock (M, G);
      if Aion.Sync.Boolean_Results.Is_Err (Done) then
         raise Program_Error with "mutex release failed in benchmark";
      end if;
   end loop;
   Stop_Time := Ada.Calendar.Clock;

   Ada.Text_IO.Put_Line
     ("iterations=" & Positive'Image (Iterations) &
      " elapsed_seconds=" & Duration'Image (Stop_Time - Start_Time));
end Bench_Sync;
