--  Broadcast channel with independent subscriber queues.

with Interfaces;
with Aion.Future;
with Aion.Result;
with Aion.Runtime;
with Aion.Sync;

package Aion.Channel.Broadcast is
   type Subscriber_Id is new Natural;
   No_Subscriber : constant Subscriber_Id := 0;

   package Subscriber_Results is new Aion.Result.Generic_Result (Subscriber_Id);

   generic
      type Message_Type is private;
   package Generic_Broadcast_Channel is
      package Message_Futures is new Aion.Future.Generic_Future (Message_Type);
      package Message_Results is new Aion.Result.Generic_Result (Message_Type);

      type Broadcast_Channel
        (Max_Subscribers : Positive := 64;
         Per_Subscriber_Capacity : Positive := 256) is limited private;

      function Subscribe
        (Channel : in out Broadcast_Channel) return Subscriber_Results.Result_Type;

      function Unsubscribe
        (Channel    : in out Broadcast_Channel;
         Subscriber : Subscriber_Id) return Aion.Sync.Boolean_Results.Result_Type;

      function Publish
        (Channel : in out Broadcast_Channel;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "broadcast.publish")
         return Aion.Sync.Boolean_Futures.Future_Handle;

      function Receive
        (Channel    : in out Broadcast_Channel;
         Subscriber : Subscriber_Id;
         Runtime    : access Aion.Runtime.Runtime_Handle := null;
         Name       : String := "broadcast.receive")
         return Message_Futures.Future_Handle;

      function Close
        (Channel : in out Broadcast_Channel;
         Reason  : String := "broadcast channel closed")
         return Aion.Sync.Boolean_Results.Result_Type;

      function Subscriber_Count_Of (Channel : Broadcast_Channel) return Natural;
      function Stats_Of (Channel : Broadcast_Channel) return Aion.Channel.Channel_Stats;

   private
      type Message_Matrix is array (Positive range <>, Positive range <>) of Message_Type;
      type Natural_Array is array (Positive range <>) of Natural;
      type Positive_Array is array (Positive range <>) of Positive;
      type Boolean_Array is array (Positive range <>) of Boolean;
      type Future_Array is array (Positive range <>) of Message_Futures.Future_Handle;
      type Pending_Value_Array is array (Positive range <>) of Message_Type;

      protected type Broadcast_State
        (Max_Subscribers : Positive;
         Per_Subscriber_Capacity : Positive) is
         procedure Subscribe (Id : out Subscriber_Id; Accepted : out Boolean);
         procedure Unsubscribe (Id : in Subscriber_Id; Accepted : out Boolean);

         procedure Publish
           (Message      : in Message_Type;
            Accepted     : out Boolean;
            Closed_Error : out Boolean;
            Wake_Count   : out Natural);

         procedure Take_Pending_Wake
           (Index  : in Positive;
            Future : out Message_Futures.Future_Handle;
            Value  : out Message_Type;
            Found  : out Boolean);

         procedure Receive
           (Id             : in Subscriber_Id;
            Future         : in Message_Futures.Future_Handle;
            Complete       : out Boolean;
            Value          : out Message_Type;
            Accepted       : out Boolean;
            Closed_Error   : out Boolean);

         procedure Close_All (Wake_Count : out Natural);

         function Subscribers return Natural;
         function Snapshot return Aion.Channel.Channel_Stats;
      private
         Closed_Flag : Boolean := False;
         Active      : Boolean_Array (1 .. Max_Subscribers) := (others => False);
         Heads       : Positive_Array (1 .. Max_Subscribers) := (others => 1);
         Tails       : Positive_Array (1 .. Max_Subscribers) := (others => 1);
         Counts      : Natural_Array (1 .. Max_Subscribers) := (others => 0);
         Buffers     : Message_Matrix (1 .. Max_Subscribers, 1 .. Per_Subscriber_Capacity);

         Waiting     : Boolean_Array (1 .. Max_Subscribers) := (others => False);
         Waiters     : Future_Array (1 .. Max_Subscribers) := (others => Message_Futures.Null_Future);

         Pending_Futures : Future_Array (1 .. Max_Subscribers) := (others => Message_Futures.Null_Future);
         Pending_Values  : Pending_Value_Array (1 .. Max_Subscribers);
         Pending_Count   : Natural := 0;

         Subscriber_Total : Natural := 0;
         Sent_Total       : Interfaces.Unsigned_64 := 0;
         Received_Total   : Interfaces.Unsigned_64 := 0;
         Wake_Total       : Interfaces.Unsigned_64 := 0;
         Dropped_Total    : Interfaces.Unsigned_64 := 0;
         Failure_Total    : Interfaces.Unsigned_64 := 0;
      end Broadcast_State;

      type Broadcast_Channel
        (Max_Subscribers : Positive := 64;
         Per_Subscriber_Capacity : Positive := 256) is limited record
         State : Broadcast_State (Max_Subscribers, Per_Subscriber_Capacity);
      end record;
   end Generic_Broadcast_Channel;
end Aion.Channel.Broadcast;
