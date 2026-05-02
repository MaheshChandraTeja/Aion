with Aion.Errors;

package body Aion.Channel.Oneshot is
   package body Generic_Oneshot_Channel is
      use type Interfaces.Unsigned_64;

      protected body Oneshot_State is
         procedure Put
           (Message       : in Message_Type;
            Sender        : in Aion.Sync.Boolean_Futures.Future_Handle;
            Complete_Send : out Boolean;
            Complete_Recv : out Boolean;
            Receiver      : out Message_Futures.Future_Handle;
            Value         : out Message_Type;
            Accepted      : out Boolean;
            Closed_Error  : out Boolean) is
            pragma Unreferenced (Sender);
         begin
            Receiver := Message_Futures.Null_Future;
            Value := Message;
            Complete_Send := False;
            Complete_Recv := False;
            Accepted := False;
            Closed_Error := False;

            if Closed_Flag then
               Failure_Total := Failure_Total + 1;
               Closed_Error := True;
            elsif Has_Value then
               Failure_Total := Failure_Total + 1;
            elsif Has_Receiver then
               Receiver := Receiver_Fut;
               Receiver_Fut := Message_Futures.Null_Future;
               Has_Receiver := False;
               Closed_Flag := True;
               Complete_Send := True;
               Complete_Recv := True;
               Accepted := True;
               Sent_Total := Sent_Total + 1;
               Received_Total := Received_Total + 1;
               Wake_Total := Wake_Total + 2;
            else
               Stored_Value := Message;
               Has_Value := True;
               Closed_Flag := True;
               Complete_Send := True;
               Accepted := True;
               Sent_Total := Sent_Total + 1;
               Wake_Total := Wake_Total + 1;
            end if;
         end Put;

         procedure Take
           (Future        : in Message_Futures.Future_Handle;
            Complete_Recv : out Boolean;
            Value         : out Message_Type;
            Accepted      : out Boolean;
            Closed_Error  : out Boolean) is
         begin
            Complete_Recv := False;
            Accepted := False;
            Closed_Error := False;
            if Has_Value then
               Value := Stored_Value;
               Has_Value := False;
               Complete_Recv := True;
               Accepted := True;
               Received_Total := Received_Total + 1;
               Wake_Total := Wake_Total + 1;
            elsif Closed_Flag then
               Failure_Total := Failure_Total + 1;
               Closed_Error := True;
            elsif Has_Receiver then
               Failure_Total := Failure_Total + 1;
            else
               Receiver_Fut := Future;
               Has_Receiver := True;
               Accepted := True;
            end if;
         end Take;

         procedure Close_State
           (Had_Receiver : out Boolean;
            Receiver     : out Message_Futures.Future_Handle) is
         begin
            Closed_Flag := True;
            Had_Receiver := Has_Receiver;
            Receiver := Receiver_Fut;
            Has_Receiver := False;
            Receiver_Fut := Message_Futures.Null_Future;
         end Close_State;

         function Closed return Boolean is
         begin
            return Closed_Flag;
         end Closed;

         function Completed return Boolean is
         begin
            return Has_Value or else Closed_Flag;
         end Completed;

         function Snapshot return Aion.Channel.Channel_Stats is
         begin
            return
              (Buffered          => (if Has_Value then 1 else 0),
               Capacity          => 1,
               Waiting_Senders   => 0,
               Waiting_Receivers => (if Has_Receiver then 1 else 0),
               Sent              => Sent_Total,
               Received          => Received_Total,
               Wakeups           => Wake_Total,
               Dropped           => 0,
               Closed            => Closed_Flag,
               Failures          => Failure_Total);
         end Snapshot;
      end Oneshot_State;

      function Send
        (Channel : in out Oneshot_Channel;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "oneshot.send")
         return Aion.Sync.Boolean_Futures.Future_Handle is
         pragma Unreferenced (Runtime);
         Future        : constant Aion.Sync.Boolean_Futures.Future_Handle :=
            Aion.Sync.Boolean_Futures.Create (Name => Name);
         Complete_Send : Boolean;
         Complete_Recv : Boolean;
         Receiver      : Message_Futures.Future_Handle;
         Value         : Message_Type := Message;
         Accepted      : Boolean;
         Closed_Error  : Boolean;
         Ignored_Bool  : Aion.Sync.Boolean_Futures.Operation_Results.Result_Type;
         Ignored_Msg   : Message_Futures.Operation_Results.Result_Type;
      begin
         Channel.State.Put
           (Message, Future, Complete_Send, Complete_Recv, Receiver, Value,
            Accepted, Closed_Error);

         if Closed_Error then
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Failure
              (Future, Aion.Errors.Resource_Closed,
               "oneshot channel is closed", "Aion.Channel.Oneshot.Send");
         elsif not Accepted then
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Failure
              (Future, Aion.Errors.Invalid_State,
               "oneshot channel already has a value or receiver", "Aion.Channel.Oneshot.Send");
         elsif Complete_Send then
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Success (Future, True);
         end if;

         if Complete_Recv then
            Ignored_Msg := Message_Futures.Complete_Success (Receiver, Value);
         end if;
         return Future;
      end Send;

      function Receive
        (Channel : in out Oneshot_Channel;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "oneshot.receive")
         return Message_Futures.Future_Handle is
         pragma Unreferenced (Runtime);
         Future        : constant Message_Futures.Future_Handle := Message_Futures.Create (Name => Name);
         Complete_Recv : Boolean;
         Value         : Message_Type;
         Accepted      : Boolean;
         Closed_Error  : Boolean;
         Ignored_Msg   : Message_Futures.Operation_Results.Result_Type;
      begin
         Channel.State.Take (Future, Complete_Recv, Value, Accepted, Closed_Error);
         if Closed_Error then
            Ignored_Msg := Message_Futures.Complete_Failure
              (Future, Aion.Errors.Resource_Closed,
               "oneshot channel is closed", "Aion.Channel.Oneshot.Receive");
         elsif not Accepted then
            Ignored_Msg := Message_Futures.Complete_Failure
              (Future, Aion.Errors.Invalid_State,
               "oneshot receiver already exists", "Aion.Channel.Oneshot.Receive");
         elsif Complete_Recv then
            Ignored_Msg := Message_Futures.Complete_Success (Future, Value);
         end if;
         return Future;
      end Receive;

      function Close
        (Channel : in out Oneshot_Channel;
         Reason  : String := "oneshot channel closed")
         return Aion.Sync.Boolean_Results.Result_Type is
         Had_Receiver : Boolean;
         Receiver     : Message_Futures.Future_Handle;
         Ignored      : Message_Futures.Operation_Results.Result_Type;
      begin
         Channel.State.Close_State (Had_Receiver, Receiver);
         if Had_Receiver then
            Ignored := Message_Futures.Complete_Failure
              (Receiver, Aion.Errors.Resource_Closed, Reason, "Aion.Channel.Oneshot.Close");
         end if;
         return Aion.Sync.Boolean_Results.Success (True);
      end Close;

      function Is_Closed (Channel : Oneshot_Channel) return Boolean is
      begin
         return Channel.State.Closed;
      end Is_Closed;

      function Is_Completed (Channel : Oneshot_Channel) return Boolean is
      begin
         return Channel.State.Completed;
      end Is_Completed;

      function Stats_Of (Channel : Oneshot_Channel) return Aion.Channel.Channel_Stats is
      begin
         return Channel.State.Snapshot;
      end Stats_Of;
   end Generic_Oneshot_Channel;
end Aion.Channel.Oneshot;
