with Aion.Errors;

package body Aion.Channel.Bounded is
   package body Generic_Bounded_Channel is
      use type Interfaces.Unsigned_64;

      protected body Channel_State is
         procedure Advance (Cursor : in out Positive; Limit : Positive) is
         begin
            if Cursor = Limit then
               Cursor := 1;
            else
               Cursor := Cursor + 1;
            end if;
         end Advance;

         procedure Push_Buffer (Value : in Message_Type) is
         begin
            Buffer (Tail) := Value;
            Advance (Tail, Capacity);
            Count := Count + 1;
         end Push_Buffer;

         procedure Pop_Buffer (Value : out Message_Type; Found : out Boolean) is
         begin
            if Count = 0 then
               Found := False;
            else
               Value := Buffer (Head);
               Advance (Head, Capacity);
               Count := Count - 1;
               Found := True;
            end if;
         end Pop_Buffer;

         procedure Push_Sender
           (Message : in Message_Type;
            Future  : in Aion.Sync.Boolean_Futures.Future_Handle;
            Accepted : out Boolean) is
         begin
            if Sender_Count >= Max_Waiters then
               Failure_Total := Failure_Total + 1;
               Accepted := False;
            else
               Sender_Queue (Sender_Tail) := (Future => Future, Value => Message);
               Advance (Sender_Tail, Max_Waiters);
               Sender_Count := Sender_Count + 1;
               Accepted := True;
            end if;
         end Push_Sender;

         procedure Pop_Sender
           (Request : out Send_Request;
            Found   : out Boolean) is
         begin
            if Sender_Count = 0 then
               Request.Future := Aion.Sync.Boolean_Futures.Null_Future;
               Found := False;
            else
               Request := Sender_Queue (Sender_Head);
               Sender_Queue (Sender_Head).Future := Aion.Sync.Boolean_Futures.Null_Future;
               Advance (Sender_Head, Max_Waiters);
               Sender_Count := Sender_Count - 1;
               Found := True;
            end if;
         end Pop_Sender;

         procedure Push_Receiver
           (Future : in Message_Futures.Future_Handle;
            Accepted : out Boolean) is
         begin
            if Receiver_Count >= Max_Waiters then
               Failure_Total := Failure_Total + 1;
               Accepted := False;
            else
               Receiver_Queue (Receiver_Tail) := Future;
               Advance (Receiver_Tail, Max_Waiters);
               Receiver_Count := Receiver_Count + 1;
               Accepted := True;
            end if;
         end Push_Receiver;

         procedure Pop_Receiver
           (Future : out Message_Futures.Future_Handle;
            Found  : out Boolean) is
         begin
            if Receiver_Count = 0 then
               Future := Message_Futures.Null_Future;
               Found := False;
            else
               Future := Receiver_Queue (Receiver_Head);
               Receiver_Queue (Receiver_Head) := Message_Futures.Null_Future;
               Advance (Receiver_Head, Max_Waiters);
               Receiver_Count := Receiver_Count - 1;
               Found := True;
            end if;
         end Pop_Receiver;

         procedure Request_Send
           (Message          : in Message_Type;
            Future           : in Aion.Sync.Boolean_Futures.Future_Handle;
            Complete_Send    : out Boolean;
            Complete_Recv    : out Boolean;
            Receiver_Future  : out Message_Futures.Future_Handle;
            Delivered_Value  : out Message_Type;
            Accepted         : out Boolean;
            Closed_Error     : out Boolean) is
            Receiver_Found : Boolean := False;
         begin
            Delivered_Value := Message;
            Receiver_Future := Message_Futures.Null_Future;
            Complete_Send := False;
            Complete_Recv := False;
            Accepted := False;
            Closed_Error := False;

            if Is_Closed_Flag then
               Failure_Total := Failure_Total + 1;
               Closed_Error := True;
               return;
            end if;

            Pop_Receiver (Receiver_Future, Receiver_Found);
            if Receiver_Found then
               Delivered_Value := Message;
               Complete_Send := True;
               Complete_Recv := True;
               Accepted := True;
               Sent_Total := Sent_Total + 1;
               Received_Total := Received_Total + 1;
               Wake_Total := Wake_Total + 2;
            elsif Count < Capacity then
               Push_Buffer (Message);
               Complete_Send := True;
               Accepted := True;
               Sent_Total := Sent_Total + 1;
               Wake_Total := Wake_Total + 1;
            else
               Push_Sender (Message, Future, Accepted);
            end if;
         end Request_Send;

         procedure Try_Send
           (Message      : in Message_Type;
            Accepted     : out Boolean;
            Closed_Error : out Boolean) is
            Receiver : Message_Futures.Future_Handle;
            Found    : Boolean;
         begin
            Accepted := False;
            Closed_Error := False;
            if Is_Closed_Flag then
               Closed_Error := True;
               Failure_Total := Failure_Total + 1;
               return;
            end if;

            Pop_Receiver (Receiver, Found);
            if Found then
               --  Try_Send has no async completion channel for a receiver; this
               --  path is intentionally not used by the public body. Kept closed
               --  inside the protected state for invariant completeness.
               Receiver_Queue (Receiver_Head) := Receiver;
               Accepted := False;
               Failure_Total := Failure_Total + 1;
            elsif Count < Capacity then
               Push_Buffer (Message);
               Sent_Total := Sent_Total + 1;
               Accepted := True;
            end if;
         end Try_Send;

         procedure Request_Receive
           (Future          : in Message_Futures.Future_Handle;
            Complete_Recv   : out Boolean;
            Received_Value  : out Message_Type;
            Complete_Send   : out Boolean;
            Sender_Future   : out Aion.Sync.Boolean_Futures.Future_Handle;
            Accepted        : out Boolean;
            Closed_And_Empty: out Boolean) is
            Found_Message : Boolean;
            Sender        : Send_Request;
            Sender_Found  : Boolean;
         begin
            Sender_Future := Aion.Sync.Boolean_Futures.Null_Future;
            Complete_Recv := False;
            Complete_Send := False;
            Accepted := False;
            Closed_And_Empty := False;

            Pop_Buffer (Received_Value, Found_Message);
            if Found_Message then
               Complete_Recv := True;
               Accepted := True;
               Received_Total := Received_Total + 1;
               Wake_Total := Wake_Total + 1;

               Pop_Sender (Sender, Sender_Found);
               if Sender_Found then
                  Push_Buffer (Sender.Value);
                  Sender_Future := Sender.Future;
                  Complete_Send := True;
                  Sent_Total := Sent_Total + 1;
                  Wake_Total := Wake_Total + 1;
               end if;
            elsif Is_Closed_Flag then
               Failure_Total := Failure_Total + 1;
               Closed_And_Empty := True;
            else
               Push_Receiver (Future, Accepted);
            end if;
         end Request_Receive;

         procedure Try_Receive
           (Found          : out Boolean;
            Value          : out Message_Type;
            Closed_And_Empty : out Boolean;
            Complete_Send  : out Boolean;
            Sender_Future  : out Aion.Sync.Boolean_Futures.Future_Handle) is
            Sender       : Send_Request;
            Sender_Found : Boolean;
         begin
            Sender_Future := Aion.Sync.Boolean_Futures.Null_Future;
            Complete_Send := False;
            Closed_And_Empty := False;
            Pop_Buffer (Value, Found);

            if Found then
               Received_Total := Received_Total + 1;
               Pop_Sender (Sender, Sender_Found);
               if Sender_Found then
                  Push_Buffer (Sender.Value);
                  Sender_Future := Sender.Future;
                  Complete_Send := True;
                  Sent_Total := Sent_Total + 1;
                  Wake_Total := Wake_Total + 1;
               end if;
            elsif Is_Closed_Flag then
               Closed_And_Empty := True;
               Failure_Total := Failure_Total + 1;
            end if;
         end Try_Receive;

         procedure Close_All
           (Receiver_Count : out Natural;
            Sender_Count   : out Natural) is
         begin
            Is_Closed_Flag := True;
            Receiver_Count := Channel_State.Receiver_Count;
            Sender_Count := Channel_State.Sender_Count;
         end Close_All;

         procedure Drain_Receiver (Index : in Positive; Future : out Message_Futures.Future_Handle) is
            pragma Unreferenced (Index);
            Found : Boolean;
         begin
            Pop_Receiver (Future, Found);
            if not Found then
               Future := Message_Futures.Null_Future;
            end if;
         end Drain_Receiver;

         procedure Drain_Sender
           (Index  : in Positive;
            Future : out Aion.Sync.Boolean_Futures.Future_Handle) is
            pragma Unreferenced (Index);
            Sender : Send_Request;
            Found  : Boolean;
         begin
            Pop_Sender (Sender, Found);
            if Found then
               Future := Sender.Future;
            else
               Future := Aion.Sync.Boolean_Futures.Null_Future;
            end if;
         end Drain_Sender;

         function Closed return Boolean is
         begin
            return Is_Closed_Flag;
         end Closed;

         function Buffered return Natural is
         begin
            return Count;
         end Buffered;

         function Sender_Waiters return Natural is
         begin
            return Sender_Count;
         end Sender_Waiters;

         function Receiver_Waiters return Natural is
         begin
            return Receiver_Count;
         end Receiver_Waiters;

         function Snapshot return Aion.Channel.Channel_Stats is
         begin
            return
              (Buffered          => Count,
               Capacity          => Capacity,
               Waiting_Senders   => Sender_Count,
               Waiting_Receivers => Receiver_Count,
               Sent              => Sent_Total,
               Received          => Received_Total,
               Wakeups           => Wake_Total,
               Dropped           => Dropped_Total,
               Closed            => Is_Closed_Flag,
               Failures          => Failure_Total);
         end Snapshot;
      end Channel_State;

      function Send
        (Channel : in out Bounded_Channel;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "bounded.send")
         return Aion.Sync.Boolean_Futures.Future_Handle is
         pragma Unreferenced (Runtime);
         Future          : constant Aion.Sync.Boolean_Futures.Future_Handle :=
           Aion.Sync.Boolean_Futures.Create (Name => Name);
         Complete_Send   : Boolean;
         Complete_Recv   : Boolean;
         Receiver_Future : Message_Futures.Future_Handle;
         Delivered       : Message_Type := Message;
         Accepted        : Boolean;
         Closed_Error    : Boolean;
         Ignored_Bool    : Aion.Sync.Boolean_Futures.Operation_Results.Result_Type;
         Ignored_Msg     : Message_Futures.Operation_Results.Result_Type;
      begin
         Channel.State.Request_Send
           (Message, Future, Complete_Send, Complete_Recv, Receiver_Future,
            Delivered, Accepted, Closed_Error);

         if Closed_Error then
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Failure
              (Future, Aion.Errors.Resource_Closed,
               "bounded channel is closed", "Aion.Channel.Bounded.Send");
         elsif not Accepted then
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Failure
              (Future, Aion.Errors.Capacity_Exceeded,
               "bounded channel sender queue is full", "Aion.Channel.Bounded.Send");
         elsif Complete_Send then
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Success (Future, True);
         end if;

         if Complete_Recv then
            Ignored_Msg := Message_Futures.Complete_Success (Receiver_Future, Delivered);
         end if;
         return Future;
      end Send;

      function Try_Send
        (Channel : in out Bounded_Channel;
         Message : Message_Type) return Aion.Sync.Boolean_Results.Result_Type is
         F : constant Aion.Sync.Boolean_Futures.Future_Handle := Send (Channel, Message, Name => "bounded.try_send");
         R : constant Aion.Sync.Boolean_Futures.Value_Results.Result_Type :=
           Aion.Sync.Boolean_Futures.Try_Value (F);
      begin
         if Aion.Sync.Boolean_Futures.Value_Results.Is_Ok (R) then
            return Aion.Sync.Boolean_Results.Success (True);
         end if;
         return Aion.Sync.Boolean_Results.Failure
           (Aion.Sync.Boolean_Futures.Value_Results.Error (R));
      end Try_Send;

      function Receive
        (Channel : in out Bounded_Channel;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "bounded.receive")
         return Message_Futures.Future_Handle is
         pragma Unreferenced (Runtime);
         Future        : constant Message_Futures.Future_Handle := Message_Futures.Create (Name => Name);
         Complete_Recv : Boolean;
         Value         : Message_Type;
         Complete_Send : Boolean;
         Sender_Future : Aion.Sync.Boolean_Futures.Future_Handle;
         Accepted      : Boolean;
         Closed_Empty  : Boolean;
         Ignored_Bool  : Aion.Sync.Boolean_Futures.Operation_Results.Result_Type;
         Ignored_Msg   : Message_Futures.Operation_Results.Result_Type;
      begin
         Channel.State.Request_Receive
           (Future, Complete_Recv, Value, Complete_Send, Sender_Future,
            Accepted, Closed_Empty);

         if Closed_Empty then
            Ignored_Msg := Message_Futures.Complete_Failure
              (Future, Aion.Errors.Resource_Closed,
               "bounded channel is closed and empty", "Aion.Channel.Bounded.Receive");
         elsif not Accepted then
            Ignored_Msg := Message_Futures.Complete_Failure
              (Future, Aion.Errors.Capacity_Exceeded,
               "bounded channel receiver queue is full", "Aion.Channel.Bounded.Receive");
         elsif Complete_Recv then
            Ignored_Msg := Message_Futures.Complete_Success (Future, Value);
         end if;

         if Complete_Send then
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Success (Sender_Future, True);
         end if;
         return Future;
      end Receive;

      function Try_Receive
        (Channel : in out Bounded_Channel) return Message_Results.Result_Type is
         F : constant Message_Futures.Future_Handle := Receive (Channel, Name => "bounded.try_receive");
         R : constant Message_Futures.Value_Results.Result_Type := Message_Futures.Try_Value (F);
      begin
         if Message_Futures.Value_Results.Is_Ok (R) then
            return Message_Results.Success (Message_Futures.Value_Results.Value (R));
         end if;
         return Message_Results.Failure (Message_Futures.Value_Results.Error (R));
      end Try_Receive;

      function Close
        (Channel : in out Bounded_Channel;
         Reason  : String := "bounded channel closed")
         return Aion.Sync.Boolean_Results.Result_Type is
         Receivers : Natural;
         Senders   : Natural;
         RF        : Message_Futures.Future_Handle;
         SF        : Aion.Sync.Boolean_Futures.Future_Handle;
         Ignored_Msg  : Message_Futures.Operation_Results.Result_Type;
         Ignored_Bool : Aion.Sync.Boolean_Futures.Operation_Results.Result_Type;
      begin
         Channel.State.Close_All (Receivers, Senders);
         for I in 1 .. Receivers loop
            Channel.State.Drain_Receiver (I, RF);
            if Message_Futures.Is_Valid (RF) then
               Ignored_Msg := Message_Futures.Complete_Failure
                 (RF, Aion.Errors.Resource_Closed, Reason, "Aion.Channel.Bounded.Close");
            end if;
         end loop;
         for I in 1 .. Senders loop
            Channel.State.Drain_Sender (I, SF);
            if Aion.Sync.Boolean_Futures.Is_Valid (SF) then
               Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Failure
                 (SF, Aion.Errors.Resource_Closed, Reason, "Aion.Channel.Bounded.Close");
            end if;
         end loop;
         return Aion.Sync.Boolean_Results.Success (True);
      end Close;

      function Is_Closed (Channel : Bounded_Channel) return Boolean is
      begin
         return Channel.State.Closed;
      end Is_Closed;

      function Buffered_Count_Of (Channel : Bounded_Channel) return Natural is
      begin
         return Channel.State.Buffered;
      end Buffered_Count_Of;

      function Sender_Waiter_Count_Of (Channel : Bounded_Channel) return Natural is
      begin
         return Channel.State.Sender_Waiters;
      end Sender_Waiter_Count_Of;

      function Receiver_Waiter_Count_Of (Channel : Bounded_Channel) return Natural is
      begin
         return Channel.State.Receiver_Waiters;
      end Receiver_Waiter_Count_Of;

      function Stats_Of (Channel : Bounded_Channel) return Aion.Channel.Channel_Stats is
      begin
         return Channel.State.Snapshot;
      end Stats_Of;
   end Generic_Bounded_Channel;
end Aion.Channel.Bounded;
