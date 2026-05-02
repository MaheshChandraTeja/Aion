--  Async event primitive with manual-reset and auto-reset modes.

with Interfaces;
with Aion.Runtime;

package Aion.Sync.Event is

   type Event_Mode is (Manual_Reset, Auto_Reset);

   package Event_Futures renames Aion.Sync.Boolean_Futures;

   type Async_Event
     (Mode        : Event_Mode := Manual_Reset;
      Initially_Set : Boolean := False;
      Max_Waiters : Positive := 4_096) is limited private;

   function Wait
     (Event   : in out Async_Event;
      Runtime : access Aion.Runtime.Runtime_Handle := null;
      Name    : String := "event.wait") return Event_Futures.Future_Handle;

   procedure Set (Event : in out Async_Event);
   procedure Reset (Event : in out Async_Event);

   function Cancel_Waiter
     (Event  : in out Async_Event;
      Future : Event_Futures.Future_Handle;
      Reason : String := "event waiter cancelled")
      return Aion.Sync.Boolean_Results.Result_Type;

   function Is_Set (Event : Async_Event) return Boolean;
   function Waiter_Count_Of (Event : Async_Event) return Natural;
   function Stats_Of (Event : Async_Event) return Aion.Sync.Primitive_Stats;

private
   type Future_Array is array (Positive range <>) of Event_Futures.Future_Handle;

   protected type Event_State
     (Mode          : Event_Mode;
      Initially_Set : Boolean;
      Max_Waiters   : Positive) is
      procedure Request_Wait
        (Future   : in Event_Futures.Future_Handle;
         Immediate : out Boolean;
         Accepted  : out Boolean);

      procedure Signal;
      procedure Clear;

      procedure Pop_Ready
        (Future : out Event_Futures.Future_Handle;
         Found  : out Boolean);

      procedure Cancel
        (Future   : in Event_Futures.Future_Handle;
         Accepted : out Boolean);

      function Signaled return Boolean;
      function Waiters return Natural;
      function Snapshot return Aion.Sync.Primitive_Stats;
   private
      Flag          : Boolean := Initially_Set;
      Queue         : Future_Array (1 .. Max_Waiters) :=
        (others => Event_Futures.Null_Future);
      Head          : Positive := 1;
      Tail          : Positive := 1;
      Count         : Natural := 0;
      Wakeups       : Interfaces.Unsigned_64 := 0;
      Acquisitions  : Interfaces.Unsigned_64 := 0;
      Releases      : Interfaces.Unsigned_64 := 0;
      Cancellations : Interfaces.Unsigned_64 := 0;
      Failures      : Interfaces.Unsigned_64 := 0;
   end Event_State;

   type Async_Event
     (Mode        : Event_Mode := Manual_Reset;
      Initially_Set : Boolean := False;
      Max_Waiters : Positive := 4_096) is limited record
      State : Event_State (Mode, Initially_Set, Max_Waiters);
   end record;

end Aion.Sync.Event;
