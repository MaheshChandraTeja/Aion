--  Runtime-owned timer queue for Aion.
--
--  The implementation is a bounded binary min-heap serviced by one timer task.
--  Timer completions are represented as Aion futures, so timer users compose
--  with the Future/Promise module instead of inventing a parallel lifecycle.

with Ada.Strings.Unbounded;
with Aion.Clock;
with Aion.Future;
with Aion.Promise;
with Aion.Result;
with Aion.Types;

package Aion.Timer_Queue is

   type Timer_Id is new Aion.Types.Task_Id;
   No_Timer : constant Timer_Id := 0;

   Default_Timer_Capacity : constant Positive := 4_096;

   package Timer_Futures is new Aion.Future.Generic_Future (Boolean);
   package Timer_Promises is new Aion.Promise.Generic_Promise (Timer_Futures);

   package US renames Ada.Strings.Unbounded;

   type Timer_Service is limited private;
   type Timer_Service_Access is access all Timer_Service;

   type Timer_Handle is record
      Id       : Timer_Id := No_Timer;
      Name     : US.Unbounded_String := US.Null_Unbounded_String;
      Deadline : Aion.Clock.Instant := Aion.Clock.Epoch;
      Future   : Timer_Futures.Future_Handle := Timer_Futures.Null_Future;
      Service  : Timer_Service_Access := null;
   end record;

   Null_Timer : constant Timer_Handle :=
     (Id       => No_Timer,
      Name     => US.Null_Unbounded_String,
      Deadline => Aion.Clock.Epoch,
      Future   => Timer_Futures.Null_Future,
      Service  => null);

   type Timer_Stats is record
      Capacity        : Natural := 0;
      Pending         : Natural := 0;
      Scheduled_Total : Natural := 0;
      Fired_Total     : Natural := 0;
      Cancelled_Total : Natural := 0;
      Rejected_Total  : Natural := 0;
      Worker_Running  : Boolean := False;
      Stop_Requested  : Boolean := False;
   end record;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);
   package Schedule_Results is new Aion.Result.Generic_Result (Timer_Handle);

   function Create_Service
     (Capacity : Positive := Default_Timer_Capacity) return Timer_Service_Access;

   procedure Stop (Service : in out Timer_Service);
   procedure Destroy (Service : in out Timer_Service_Access);

   function Schedule
     (Service : not null Timer_Service_Access;
      Delay_Ms : Aion.Types.Milliseconds;
      Name    : String := "timer") return Schedule_Results.Result_Type;

   function Schedule_At
     (Service  : not null Timer_Service_Access;
      Deadline : Aion.Clock.Instant;
      Name     : String := "timer") return Schedule_Results.Result_Type;

   function Cancel (Timer : Timer_Handle) return Operation_Results.Result_Type;

   function Is_Valid (Timer : Timer_Handle) return Boolean;
   function Id_Of (Timer : Timer_Handle) return Timer_Id;
   function Name_Of (Timer : Timer_Handle) return String;
   function Deadline_Of (Timer : Timer_Handle) return Aion.Clock.Instant;
   function Future_Of (Timer : Timer_Handle) return Timer_Futures.Future_Handle;

   function Stats_Of (Service : Timer_Service) return Timer_Stats;
   function Pending_Count_Of (Service : Timer_Service) return Natural;
   function Is_Stopping (Service : Timer_Service) return Boolean;

   function Image (Timer : Timer_Handle) return String;
   function Image (Stats : Timer_Stats) return String;

private
   type Timer_Record is record
      Id       : Timer_Id := No_Timer;
      Name     : US.Unbounded_String := US.Null_Unbounded_String;
      Deadline : Aion.Clock.Instant := Aion.Clock.Epoch;
      Promise  : Timer_Promises.Promise_Handle := Timer_Promises.Null_Promise;
      Future   : Timer_Futures.Future_Handle := Timer_Futures.Null_Future;
   end record;

   Null_Record : constant Timer_Record :=
     (Id       => No_Timer,
      Name     => US.Null_Unbounded_String,
      Deadline => Aion.Clock.Epoch,
      Promise  => Timer_Promises.Null_Promise,
      Future   => Timer_Futures.Null_Future);

   type Timer_Array is array (Positive range <>) of Timer_Record;

   protected type Timer_Registry (Max_Capacity : Positive) is
      procedure Insert
        (Item     : in Timer_Record;
         Accepted : out Boolean);

      procedure Cancel
        (Id    : in Timer_Id;
         Item  : out Timer_Record;
         Found : out Boolean);

      procedure Pop_Due
        (Now   : in Aion.Clock.Instant;
         Item  : out Timer_Record;
         Found : out Boolean);

      procedure Pop_Any
        (Item  : out Timer_Record;
         Found : out Boolean);

      procedure Request_Stop;
      procedure Mark_Worker_Started;
      procedure Mark_Worker_Stopped;

      function Next_Wait return Duration;
      function Depth return Natural;
      function Capacity return Natural;
      function Stopping return Boolean;
      function Worker_Running return Boolean;
      function Snapshot return Timer_Stats;
   private
      procedure Swap (Left, Right : Positive);
      procedure Bubble_Up (Index : Positive);
      procedure Bubble_Down (Index : Positive);
      procedure Remove_At
        (Index : Positive;
         Item  : out Timer_Record);

      Heap : Timer_Array (1 .. Max_Capacity);
      Count : Natural := 0;
      Stop_Requested : Boolean := False;
      Worker_Started : Boolean := False;
      Worker_Stopped : Boolean := False;

      Scheduled_Total : Natural := 0;
      Fired_Total     : Natural := 0;
      Cancelled_Total : Natural := 0;
      Rejected_Total  : Natural := 0;
   end Timer_Registry;

   type Timer_Registry_Access is access all Timer_Registry;

   task type Timer_Worker (Registry : not null Timer_Registry_Access);
   type Timer_Worker_Access is access Timer_Worker;

   type Timer_Service is limited record
      Registry : Timer_Registry_Access := null;
      Worker   : Timer_Worker_Access := null;
   end record;

end Aion.Timer_Queue;
