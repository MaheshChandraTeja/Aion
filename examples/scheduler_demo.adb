with Ada.Text_IO;
with Aion.Scheduler;
use type Aion.Scheduler.Job_Procedure;
with Aion.Task_Handle;
with Aion_Example_Jobs;

procedure Scheduler_Demo is
   Queue    : Aion.Scheduler.Job_Queue (Max_Capacity => 4);
   Handle   : Aion.Task_Handle.Task_Handle :=
     Aion.Task_Handle.Create (1, "manual-scheduler-job");
   Job      : Aion.Scheduler.Job_Item :=
     Aion.Scheduler.Make_Job (Handle, Aion_Example_Jobs.Increment'Access);
   Taken    : Aion.Scheduler.Job_Item;
   Accepted : Boolean := False;
   Found    : Boolean := False;
begin
   Aion_Example_Jobs.Reset;
   Queue.Try_Enqueue (Job, Accepted);

   if Accepted then
      Queue.Take (Taken, Found);

      if Found then
         declare
            Work : constant Aion.Scheduler.Job_Procedure :=
              Aion.Scheduler.Work_Of (Taken);
         begin
            if Work /= null then
               Work.all;
            end if;
         end;
      end if;
   end if;

   Ada.Text_IO.Put_Line
     ("manual scheduler count=" & Natural'Image (Aion_Example_Jobs.Count));
end Scheduler_Demo;
