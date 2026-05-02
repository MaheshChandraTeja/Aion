--  Bounded multi-producer/multi-consumer async channel.
--
--  Send and Receive return futures. If the channel can complete immediately,
--  the returned future is completed before return. Otherwise it remains pending
--  until capacity/messages become available or the channel is closed.

with Interfaces;
with Aion.Future;
with Aion.Result;
with Aion.Runtime;
with Aion.Sync;

package Aion.Channel.Bounded is
   generic
      type Message_Type is private;
   package Generic_Bounded_Channel is
      package Message_Futures is new Aion.Future.Generic_Future (Message_Type);
      package Message_Results is new Aion.Result.Generic_Result (Message_Type);

      type Bounded_Channel
        (Capacity    : Positive := 128;
         Max_Waiters : Positive := 4_096) is limited private;

      function Send
        (Channel : in out Bounded_Channel;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "bounded.send")
         return Aion.Sync.Boolean_Futures.Future_Handle;

      function Try_Send
        (Channel : in out Bounded_Channel;
         Message : Message_Type) return Aion.Sync.Boolean_Results.Result_Type;

      function Receive
        (Channel : in out Bounded_Channel;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "bounded.receive")
         return Message_Futures.Future_Handle;

      function Try_Receive
        (Channel : in out Bounded_Channel) return Message_Results.Result_Type;

      function Close
        (Channel : in out Bounded_Channel;
         Reason  : String := "bounded channel closed")
         return Aion.Sync.Boolean_Results.Result_Type;

      function Is_Closed (Channel : Bounded_Channel) return Boolean;
      function Buffered_Count_Of (Channel : Bounded_Channel) return Natural;
      function Sender_Waiter_Count_Of (Channel : Bounded_Channel) return Natural;
      function Receiver_Waiter_Count_Of (Channel : Bounded_Channel) return Natural;
      function Stats_Of (Channel : Bounded_Channel) return Aion.Channel.Channel_Stats;

   private
      type Message_Array is array (Positive range <>) of Message_Type;
      type Send_Request is record
         Future : Aion.Sync.Boolean_Futures.Future_Handle :=
           Aion.Sync.Boolean_Futures.Null_Future;
         Value  : Message_Type;
      end record;
      type Send_Request_Array is array (Positive range <>) of Send_Request;
      type Receive_Future_Array is array (Positive range <>) of Message_Futures.Future_Handle;

      protected type Channel_State
        (Capacity    : Positive;
         Max_Waiters : Positive) is
         procedure Request_Send
           (Message          : in Message_Type;
            Future           : in Aion.Sync.Boolean_Futures.Future_Handle;
            Complete_Send    : out Boolean;
            Complete_Recv    : out Boolean;
            Receiver_Future  : out Message_Futures.Future_Handle;
            Delivered_Value  : out Message_Type;
            Accepted         : out Boolean;
            Closed_Error     : out Boolean);

         procedure Try_Send
           (Message      : in Message_Type;
            Accepted     : out Boolean;
            Closed_Error : out Boolean);

         procedure Request_Receive
           (Future          : in Message_Futures.Future_Handle;
            Complete_Recv   : out Boolean;
            Received_Value  : out Message_Type;
            Complete_Send   : out Boolean;
            Sender_Future   : out Aion.Sync.Boolean_Futures.Future_Handle;
            Accepted        : out Boolean;
            Closed_And_Empty: out Boolean);

         procedure Try_Receive
           (Found          : out Boolean;
            Value          : out Message_Type;
            Closed_And_Empty : out Boolean;
            Complete_Send  : out Boolean;
            Sender_Future  : out Aion.Sync.Boolean_Futures.Future_Handle);

         procedure Close_All
           (Receiver_Count : out Natural;
            Sender_Count   : out Natural);

         procedure Drain_Receiver (Index : in Positive; Future : out Message_Futures.Future_Handle);
         procedure Drain_Sender
           (Index  : in Positive;
            Future : out Aion.Sync.Boolean_Futures.Future_Handle);

         function Closed return Boolean;
         function Buffered return Natural;
         function Sender_Waiters return Natural;
         function Receiver_Waiters return Natural;
         function Snapshot return Aion.Channel.Channel_Stats;
      private
         Is_Closed_Flag : Boolean := False;
         Buffer         : Message_Array (1 .. Capacity);
         Head           : Positive := 1;
         Tail           : Positive := 1;
         Count          : Natural := 0;

         Sender_Queue   : Send_Request_Array (1 .. Max_Waiters);
         Sender_Head    : Positive := 1;
         Sender_Tail    : Positive := 1;
         Sender_Count   : Natural := 0;

         Receiver_Queue : Receive_Future_Array (1 .. Max_Waiters) :=
           (others => Message_Futures.Null_Future);
         Receiver_Head  : Positive := 1;
         Receiver_Tail  : Positive := 1;
         Receiver_Count : Natural := 0;

         Sent_Total     : Interfaces.Unsigned_64 := 0;
         Received_Total : Interfaces.Unsigned_64 := 0;
         Wake_Total     : Interfaces.Unsigned_64 := 0;
         Dropped_Total  : Interfaces.Unsigned_64 := 0;
         Failure_Total  : Interfaces.Unsigned_64 := 0;
      end Channel_State;

      type Bounded_Channel
        (Capacity    : Positive := 128;
         Max_Waiters : Positive := 4_096) is limited record
         State : Channel_State (Capacity, Max_Waiters);
      end record;
   end Generic_Bounded_Channel;
end Aion.Channel.Bounded;
