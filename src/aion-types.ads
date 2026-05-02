--  Shared public types used throughout Aion.
--  Future modules must reuse these definitions instead of inventing local
--  timeout, state, or status types.

with Interfaces;

package Aion.Types is
   pragma Preelaborate;

   subtype Worker_Count is Positive range 1 .. 256;
   subtype Queue_Capacity is Natural range 0 .. 1_000_000;

   type Milliseconds is new Interfaces.Unsigned_64;
   type Task_Id is new Interfaces.Unsigned_64;

   No_Task : constant Task_Id := 0;

   type Runtime_State is
     (Runtime_Created,
      Runtime_Initializing,
      Runtime_Running,
      Runtime_Stopping,
      Runtime_Stopped,
      Runtime_Failed);

   type Task_State is
     (Task_Pending,
      Task_Scheduled,
      Task_Running,
      Task_Completed,
      Task_Cancelled,
      Task_Faulted);

   type Shutdown_Mode is
     (Shutdown_Graceful,
      Shutdown_Immediate);

   type Log_Level is
     (Log_Trace,
      Log_Debug,
      Log_Info,
      Log_Warn,
      Log_Error,
      Log_Off);

   type Resource_State is
     (Resource_Open,
      Resource_Closing,
      Resource_Closed);

   function Image (Value : Runtime_State) return String;
   function Image (Value : Task_State) return String;
   function Image (Value : Shutdown_Mode) return String;
   function Image (Value : Log_Level) return String;
   function Image (Value : Resource_State) return String;
   function Image (Value : Milliseconds) return String;
   function Image (Value : Task_Id) return String;

   function Is_Terminal (Value : Task_State) return Boolean;
   function Is_Running (Value : Runtime_State) return Boolean;
end Aion.Types;
