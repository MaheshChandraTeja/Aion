package body Aion.Scheduler is

   function Make_Job
     (Handle : Aion.Task_Handle.Task_Handle;
      Work   : Job_Procedure) return Job_Item is
   begin
      return Job_Item'(Handle => Handle, Work => Work);
   end Make_Job;

   function Is_Valid (Item : Job_Item) return Boolean is
   begin
      return Aion.Task_Handle.Is_Valid (Item.Handle) and then Item.Work /= null;
   end Is_Valid;

   function Handle_Of (Item : Job_Item) return Aion.Task_Handle.Task_Handle is
   begin
      return Item.Handle;
   end Handle_Of;

   function Work_Of (Item : Job_Item) return Job_Procedure is
   begin
      return Item.Work;
   end Work_Of;

   function Image (Item : Job_Item) return String is
   begin
      if not Is_Valid (Item) then
         return "Job_Item(null)";
      end if;

      return "Job_Item(" & Aion.Task_Handle.Image (Item.Handle) & ")";
   end Image;

   protected body Job_Queue is
      procedure Try_Enqueue
        (Item     : in Job_Item;
         Accepted : out Boolean) is
      begin
         if Stop_Requested or else not Is_Valid (Item) then
            Accepted := False;
            Rejected := Rejected + 1;
            return;
         end if;

         if Count >= Max_Capacity then
            Accepted := False;
            Rejected := Rejected + 1;
            return;
         end if;

         Buffer (Tail) := Item;

         if Tail = Max_Capacity then
            Tail := 1;
         else
            Tail := Tail + 1;
         end if;

         Count := Count + 1;
         Enqueued := Enqueued + 1;
         Accepted := True;
      end Try_Enqueue;

      entry Take
        (Item  : out Job_Item;
         Found : out Boolean)
        when Count > 0 or else Stop_Requested is
      begin
         if Count = 0 then
            Item := Null_Job;
            Found := False;
            return;
         end if;

         Item := Buffer (Head);
         Buffer (Head) := Null_Job;

         if Head = Max_Capacity then
            Head := 1;
         else
            Head := Head + 1;
         end if;

         Count := Count - 1;
         Dequeued := Dequeued + 1;
         Found := True;
      end Take;

      procedure Request_Stop is
      begin
         Stop_Requested := True;
      end Request_Stop;

      procedure Request_Stop_Now (Dropped : out Natural) is
      begin
         Dropped := Count;

         for Index in Buffer'Range loop
            Buffer (Index) := Null_Job;
         end loop;

         Count := 0;
         Head := 1;
         Tail := 1;
         Stop_Requested := True;
      end Request_Stop_Now;

      procedure Clear (Dropped : out Natural) is
      begin
         Dropped := Count;

         for Index in Buffer'Range loop
            Buffer (Index) := Null_Job;
         end loop;

         Count := 0;
         Head := 1;
         Tail := 1;
      end Clear;

      function Is_Stopping return Boolean is
      begin
         return Stop_Requested;
      end Is_Stopping;

      function Depth return Natural is
      begin
         return Count;
      end Depth;

      function Capacity return Natural is
      begin
         return Max_Capacity;
      end Capacity;

      function Total_Enqueued return Natural is
      begin
         return Enqueued;
      end Total_Enqueued;

      function Total_Dequeued return Natural is
      begin
         return Dequeued;
      end Total_Dequeued;

      function Total_Rejected return Natural is
      begin
         return Rejected;
      end Total_Rejected;
   end Job_Queue;

end Aion.Scheduler;
