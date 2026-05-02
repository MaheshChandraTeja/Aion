--  Oneshot channel for exactly one value.

with Interfaces;
with Aion.Future;
with Aion.Result;
with Aion.Runtime;
with Aion.Sync;

package Aion.Channel.Oneshot is
   generic
      type Message_Type is private;
   package Generic_Oneshot_Channel is
      package Message_Futures is new Aion.Future.Generic_Future (Message_Type);
      package Message_Results is new Aion.Result.Generic_Result (Message_Type);

      type Oneshot_Channel is limited private;

      function Send
        (Channel : in out Oneshot_Channel;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "oneshot.send")
         return Aion.Sync.Boolean_Futures.Future_Handle;

      function Receive
        (Channel : in out Oneshot_Channel;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "oneshot.receive")
         return Message_Futures.Future_Handle;

      function Close
        (Channel : in out Oneshot_Channel;
         Reason  : String := "oneshot channel closed")
         return Aion.Sync.Boolean_Results.Result_Type;

      function Is_Closed (Channel : Oneshot_Channel) return Boolean;
      function Is_Completed (Channel : Oneshot_Channel) return Boolean;
      function Stats_Of (Channel : Oneshot_Channel) return Aion.Channel.Channel_Stats;

   private
      protected type Oneshot_State is
         procedure Put
           (Message       : in Message_Type;
            Sender        : in Aion.Sync.Boolean_Futures.Future_Handle;
            Complete_Send : out Boolean;
            Complete_Recv : out Boolean;
            Receiver      : out Message_Futures.Future_Handle;
            Value         : out Message_Type;
            Accepted      : out Boolean;
            Closed_Error  : out Boolean);

         procedure Take
           (Future        : in Message_Futures.Future_Handle;
            Complete_Recv : out Boolean;
            Value         : out Message_Type;
            Accepted      : out Boolean;
            Closed_Error  : out Boolean);

         procedure Close_State
           (Had_Receiver : out Boolean;
            Receiver     : out Message_Futures.Future_Handle);

         function Closed return Boolean;
         function Completed return Boolean;
         function Snapshot return Aion.Channel.Channel_Stats;
      private
         Closed_Flag    : Boolean := False;
         Has_Value      : Boolean := False;
         Has_Receiver   : Boolean := False;
         Stored_Value   : Message_Type;
         Receiver_Fut   : Message_Futures.Future_Handle := Message_Futures.Null_Future;
         Sent_Total     : Interfaces.Unsigned_64 := 0;
         Received_Total : Interfaces.Unsigned_64 := 0;
         Wake_Total     : Interfaces.Unsigned_64 := 0;
         Failure_Total  : Interfaces.Unsigned_64 := 0;
      end Oneshot_State;

      type Oneshot_Channel is limited record
         State : Oneshot_State;
      end record;
   end Generic_Oneshot_Channel;
end Aion.Channel.Oneshot;
