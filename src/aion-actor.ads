--  Actor mailbox utilities built on Aion channels.
--
--  This package intentionally supplies the serialized mailbox foundation. Module
--  9 supervision can later own lifecycle/restart policy without changing this
--  API.

with Interfaces;
with Aion.Channel;
with Aion.Channel.Bounded;
with Aion.Runtime;
with Aion.Sync;

package Aion.Actor is
   type Dispatch_Stats is record
      Queued     : Natural := 0;
      Dispatched : Interfaces.Unsigned_64 := 0;
      Failures   : Interfaces.Unsigned_64 := 0;
   end record;

   generic
      type Message_Type is private;
      with procedure Handle (Message : in Message_Type);
   package Generic_Actor is
      package Mailbox_Channel is new Aion.Channel.Bounded.Generic_Bounded_Channel (Message_Type);
      package Message_Futures renames Mailbox_Channel.Message_Futures;

      type Actor_Mailbox
        (Capacity    : Positive := 1_024;
         Max_Waiters : Positive := 4_096) is limited private;

      function Send
        (Mailbox : in out Actor_Mailbox;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "actor.send")
         return Aion.Sync.Boolean_Futures.Future_Handle;

      function Dispatch_One
        (Mailbox : in out Actor_Mailbox) return Aion.Sync.Boolean_Results.Result_Type;

      function Drain
        (Mailbox : in out Actor_Mailbox;
         Limit   : Natural := Natural'Last) return Aion.Sync.Boolean_Results.Result_Type;

      function Close
        (Mailbox : in out Actor_Mailbox;
         Reason  : String := "actor mailbox closed") return Aion.Sync.Boolean_Results.Result_Type;

      function Stats_Of (Mailbox : Actor_Mailbox) return Dispatch_Stats;
      function Channel_Stats_Of (Mailbox : Actor_Mailbox) return Aion.Channel.Channel_Stats;

   private
      protected type Actor_State is
         procedure Mark_Dispatched;
         procedure Mark_Failed;
         function Snapshot (Queued : Natural) return Dispatch_Stats;
      private
         Dispatched_Total : Interfaces.Unsigned_64 := 0;
         Failure_Total    : Interfaces.Unsigned_64 := 0;
      end Actor_State;

      type Actor_Mailbox
        (Capacity    : Positive := 1_024;
         Max_Waiters : Positive := 4_096) is limited record
         Queue : Mailbox_Channel.Bounded_Channel (Capacity, Max_Waiters);
         State : Actor_State;
      end record;
   end Generic_Actor;
end Aion.Actor;
