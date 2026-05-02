--  Runtime scheduler queue for Aion worker tasks.
--  This package owns the bounded MPMC-style job queue used by the runtime.
--  It deliberately knows nothing about networking, timers, or futures.

with Aion.Task_Handle;

package Aion.Scheduler is

   type Job_Procedure is access procedure;

   type Job_Item is private;
   type Job_Array is array (Positive range <>) of Job_Item;

   Null_Job : constant Job_Item;

   function Make_Job
     (Handle : Aion.Task_Handle.Task_Handle;
      Work   : Job_Procedure) return Job_Item;

   function Is_Valid (Item : Job_Item) return Boolean;
   function Handle_Of (Item : Job_Item) return Aion.Task_Handle.Task_Handle;
   function Work_Of (Item : Job_Item) return Job_Procedure;
   function Image (Item : Job_Item) return String;

   protected type Job_Queue (Max_Capacity : Positive) is
      procedure Try_Enqueue
        (Item     : in Job_Item;
         Accepted : out Boolean);

      entry Take
        (Item  : out Job_Item;
         Found : out Boolean);

      procedure Request_Stop;
      procedure Request_Stop_Now (Dropped : out Natural);
      procedure Clear (Dropped : out Natural);

      function Is_Stopping return Boolean;
      function Depth return Natural;
      function Capacity return Natural;
      function Total_Enqueued return Natural;
      function Total_Dequeued return Natural;
      function Total_Rejected return Natural;
   private
      Buffer : Job_Array (1 .. Max_Capacity);
      Head   : Positive := 1;
      Tail   : Positive := 1;
      Count  : Natural := 0;

      Stop_Requested : Boolean := False;
      Enqueued       : Natural := 0;
      Dequeued       : Natural := 0;
      Rejected       : Natural := 0;
   end Job_Queue;

   type Job_Queue_Access is access all Job_Queue;

private
   type Job_Item is record
      Handle : Aion.Task_Handle.Task_Handle := Aion.Task_Handle.Null_Handle;
      Work   : Job_Procedure := null;
   end record;

   Null_Job : constant Job_Item :=
     (Handle => Aion.Task_Handle.Null_Handle,
      Work   => null);

end Aion.Scheduler;
