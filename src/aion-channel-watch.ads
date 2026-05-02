--  Watch channel carrying the latest value to subscribers.

with Interfaces;
with Aion.Channel.Broadcast;
with Aion.Future;
with Aion.Result;
with Aion.Runtime;
with Aion.Sync;

package Aion.Channel.Watch is
   subtype Subscriber_Id is Aion.Channel.Broadcast.Subscriber_Id;
   No_Subscriber : constant Subscriber_Id := Aion.Channel.Broadcast.No_Subscriber;
   package Subscriber_Results renames Aion.Channel.Broadcast.Subscriber_Results;

   generic
      type Message_Type is private;
   package Generic_Watch_Channel is
      package Message_Futures is new Aion.Future.Generic_Future (Message_Type);
      package Message_Results is new Aion.Result.Generic_Result (Message_Type);

      type Watch_Channel (Max_Subscribers : Positive := 64) is limited private;

      procedure Initialize
        (Channel : in out Watch_Channel;
         Initial : Message_Type);

      function Subscribe
        (Channel : in out Watch_Channel) return Subscriber_Results.Result_Type;

      function Publish
        (Channel : in out Watch_Channel;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "watch.publish")
         return Aion.Sync.Boolean_Futures.Future_Handle;

      function Receive_Changed
        (Channel    : in out Watch_Channel;
         Subscriber : Subscriber_Id;
         Runtime    : access Aion.Runtime.Runtime_Handle := null;
         Name       : String := "watch.changed")
         return Message_Futures.Future_Handle;

      function Current
        (Channel : in out Watch_Channel) return Message_Results.Result_Type;

      function Close
        (Channel : in out Watch_Channel;
         Reason  : String := "watch channel closed")
         return Aion.Sync.Boolean_Results.Result_Type;

      function Stats_Of (Channel : Watch_Channel) return Aion.Channel.Channel_Stats;

   private
      type Version_Type is new Interfaces.Unsigned_64;
      type Boolean_Array is array (Positive range <>) of Boolean;
      type Version_Array is array (Positive range <>) of Version_Type;
      type Future_Array is array (Positive range <>) of Message_Futures.Future_Handle;
      type Value_Array is array (Positive range <>) of Message_Type;

      protected type Watch_State (Max_Subscribers : Positive) is
         procedure Initialize (Initial : in Message_Type);
         procedure Subscribe (Id : out Subscriber_Id; Accepted : out Boolean);
         procedure Publish
           (Message      : in Message_Type;
            Accepted     : out Boolean;
            Closed_Error : out Boolean;
            Wake_Count   : out Natural);
         procedure Take_Pending_Wake
           (Index : in Positive;
            Future : out Message_Futures.Future_Handle;
            Value : out Message_Type;
            Found : out Boolean);
         procedure Receive_Changed
           (Id : in Subscriber_Id;
            Future : in Message_Futures.Future_Handle;
            Complete : out Boolean;
            Value : out Message_Type;
            Accepted : out Boolean;
            Closed_Error : out Boolean);
         procedure Read_Current
           (Found : out Boolean;
            Value : out Message_Type;
            Closed_Error : out Boolean);
         procedure Close_All (Wake_Count : out Natural);
         function Snapshot return Aion.Channel.Channel_Stats;
      private
         Initialized : Boolean := False;
         Closed_Flag : Boolean := False;
         Latest      : Message_Type;
         Version     : Version_Type := 0;
         Active      : Boolean_Array (1 .. Max_Subscribers) := (others => False);
         Last_Seen   : Version_Array (1 .. Max_Subscribers) := (others => 0);
         Waiting     : Boolean_Array (1 .. Max_Subscribers) := (others => False);
         Waiters     : Future_Array (1 .. Max_Subscribers) := (others => Message_Futures.Null_Future);
         Pending_Futures : Future_Array (1 .. Max_Subscribers) := (others => Message_Futures.Null_Future);
         Pending_Values  : Value_Array (1 .. Max_Subscribers);
         Pending_Count   : Natural := 0;
         Subscriber_Total : Natural := 0;
         Sent_Total       : Interfaces.Unsigned_64 := 0;
         Received_Total   : Interfaces.Unsigned_64 := 0;
         Wake_Total       : Interfaces.Unsigned_64 := 0;
         Failure_Total    : Interfaces.Unsigned_64 := 0;
      end Watch_State;

      type Watch_Channel (Max_Subscribers : Positive := 64) is limited record
         State : Watch_State (Max_Subscribers);
      end record;
   end Generic_Watch_Channel;
end Aion.Channel.Watch;
