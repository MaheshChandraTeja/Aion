with Aion.Errors;

package body Aion.Channel.Broadcast is
   package body Generic_Broadcast_Channel is
      use type Interfaces.Unsigned_64;

      protected body Broadcast_State is
         procedure Advance (Cursor : in out Positive) is
         begin
            if Cursor = Per_Subscriber_Capacity then
               Cursor := 1;
            else
               Cursor := Cursor + 1;
            end if;
         end Advance;

         procedure Queue_For (Sub : Positive; Message : in Message_Type) is
         begin
            if Counts (Sub) = Per_Subscriber_Capacity then
               Advance (Heads (Sub));
               Counts (Sub) := Counts (Sub) - 1;
               Dropped_Total := Dropped_Total + 1;
            end if;
            Buffers (Sub, Tails (Sub)) := Message;
            Advance (Tails (Sub));
            Counts (Sub) := Counts (Sub) + 1;
         end Queue_For;

         procedure Pop_For (Sub : Positive; Value : out Message_Type; Found : out Boolean) is
         begin
            if Counts (Sub) = 0 then
               Found := False;
            else
               Value := Buffers (Sub, Heads (Sub));
               Advance (Heads (Sub));
               Counts (Sub) := Counts (Sub) - 1;
               Found := True;
            end if;
         end Pop_For;

         procedure Subscribe (Id : out Subscriber_Id; Accepted : out Boolean) is
         begin
            Id := No_Subscriber;
            Accepted := False;
            if Closed_Flag then
               Failure_Total := Failure_Total + 1;
               return;
            end if;
            for I in Active'Range loop
               if not Active (I) then
                  Active (I) := True;
                  Heads (I) := 1;
                  Tails (I) := 1;
                  Counts (I) := 0;
                  Waiting (I) := False;
                  Waiters (I) := Message_Futures.Null_Future;
                  Subscriber_Total := Subscriber_Total + 1;
                  Id := Subscriber_Id (I);
                  Accepted := True;
                  return;
               end if;
            end loop;
            Failure_Total := Failure_Total + 1;
         end Subscribe;

         procedure Unsubscribe (Id : in Subscriber_Id; Accepted : out Boolean) is
            I : constant Natural := Natural (Id);
         begin
            Accepted := False;
            if I in Active'Range and then Active (I) then
               Active (I) := False;
               Waiting (I) := False;
               Waiters (I) := Message_Futures.Null_Future;
               Counts (I) := 0;
               Subscriber_Total := Subscriber_Total - 1;
               Accepted := True;
            else
               Failure_Total := Failure_Total + 1;
            end if;
         end Unsubscribe;

         procedure Publish
           (Message      : in Message_Type;
            Accepted     : out Boolean;
            Closed_Error : out Boolean;
            Wake_Count   : out Natural) is
         begin
            Accepted := False;
            Closed_Error := False;
            Wake_Count := 0;
            Pending_Count := 0;

            if Closed_Flag then
               Failure_Total := Failure_Total + 1;
               Closed_Error := True;
               return;
            end if;

            for I in Active'Range loop
               if Active (I) then
                  if Waiting (I) then
                     Pending_Count := Pending_Count + 1;
                     Pending_Futures (Pending_Count) := Waiters (I);
                     Pending_Values (Pending_Count) := Message;
                     Waiters (I) := Message_Futures.Null_Future;
                     Waiting (I) := False;
                     Wake_Count := Wake_Count + 1;
                     Wake_Total := Wake_Total + 1;
                     Received_Total := Received_Total + 1;
                  else
                     Queue_For (I, Message);
                  end if;
               end if;
            end loop;
            Sent_Total := Sent_Total + 1;
            Accepted := True;
         end Publish;

         procedure Take_Pending_Wake
           (Index  : in Positive;
            Future : out Message_Futures.Future_Handle;
            Value  : out Message_Type;
            Found  : out Boolean) is
         begin
            if Index <= Pending_Count then
               Future := Pending_Futures (Index);
               Value := Pending_Values (Index);
               Found := True;
            else
               Future := Message_Futures.Null_Future;
               Found := False;
            end if;
         end Take_Pending_Wake;

         procedure Receive
           (Id             : in Subscriber_Id;
            Future         : in Message_Futures.Future_Handle;
            Complete       : out Boolean;
            Value          : out Message_Type;
            Accepted       : out Boolean;
            Closed_Error   : out Boolean) is
            I : constant Natural := Natural (Id);
            Found : Boolean := False;
         begin
            Complete := False;
            Accepted := False;
            Closed_Error := False;

            if not (I in Active'Range) or else not Active (I) then
               Failure_Total := Failure_Total + 1;
               return;
            end if;

            Pop_For (I, Value, Found);
            if Found then
               Complete := True;
               Accepted := True;
               Received_Total := Received_Total + 1;
               Wake_Total := Wake_Total + 1;
            elsif Closed_Flag then
               Closed_Error := True;
               Failure_Total := Failure_Total + 1;
            elsif Waiting (I) then
               Failure_Total := Failure_Total + 1;
            else
               Waiters (I) := Future;
               Waiting (I) := True;
               Accepted := True;
            end if;
         end Receive;

         procedure Close_All (Wake_Count : out Natural) is
         begin
            Closed_Flag := True;
            Pending_Count := 0;
            Wake_Count := 0;
            for I in Active'Range loop
               if Active (I) and then Waiting (I) then
                  Pending_Count := Pending_Count + 1;
                  Pending_Futures (Pending_Count) := Waiters (I);
                  Waiters (I) := Message_Futures.Null_Future;
                  Waiting (I) := False;
                  Wake_Count := Wake_Count + 1;
               end if;
            end loop;
         end Close_All;

         function Subscribers return Natural is
         begin
            return Subscriber_Total;
         end Subscribers;

         function Snapshot return Aion.Channel.Channel_Stats is
            Buffered_Total : Natural := 0;
            Waiting_Total  : Natural := 0;
         begin
            for I in Active'Range loop
               if Active (I) then
                  Buffered_Total := Buffered_Total + Counts (I);
                  if Waiting (I) then
                     Waiting_Total := Waiting_Total + 1;
                  end if;
               end if;
            end loop;
            return
              (Buffered          => Buffered_Total,
               Capacity          => Max_Subscribers * Per_Subscriber_Capacity,
               Waiting_Senders   => 0,
               Waiting_Receivers => Waiting_Total,
               Sent              => Sent_Total,
               Received          => Received_Total,
               Wakeups           => Wake_Total,
               Dropped           => Dropped_Total,
               Closed            => Closed_Flag,
               Failures          => Failure_Total);
         end Snapshot;
      end Broadcast_State;

      function Subscribe
        (Channel : in out Broadcast_Channel) return Subscriber_Results.Result_Type is
         Id : Subscriber_Id;
         Accepted : Boolean;
      begin
         Channel.State.Subscribe (Id, Accepted);
         if Accepted then
            return Subscriber_Results.Success (Id);
         end if;
         return Subscriber_Results.Failure
           (Aion.Errors.Capacity_Exceeded,
            "broadcast channel has no subscriber slots", "Aion.Channel.Broadcast.Subscribe");
      end Subscribe;

      function Unsubscribe
        (Channel    : in out Broadcast_Channel;
         Subscriber : Subscriber_Id) return Aion.Sync.Boolean_Results.Result_Type is
         Accepted : Boolean;
      begin
         Channel.State.Unsubscribe (Subscriber, Accepted);
         if Accepted then
            return Aion.Sync.Boolean_Results.Success (True);
         end if;
         return Aion.Sync.Boolean_Results.Failure
           (Aion.Errors.Invalid_Argument,
            "unknown broadcast subscriber", "Aion.Channel.Broadcast.Unsubscribe");
      end Unsubscribe;

      function Publish
        (Channel : in out Broadcast_Channel;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "broadcast.publish")
         return Aion.Sync.Boolean_Futures.Future_Handle is
         pragma Unreferenced (Runtime);
         Future : constant Aion.Sync.Boolean_Futures.Future_Handle :=
           Aion.Sync.Boolean_Futures.Create (Name => Name);
         Accepted, Closed_Error : Boolean;
         Wake_Count : Natural;
         RF : Message_Futures.Future_Handle;
         V  : Message_Type := Message;
         Found : Boolean;
         Ignored_Bool : Aion.Sync.Boolean_Futures.Operation_Results.Result_Type;
         Ignored_Msg  : Message_Futures.Operation_Results.Result_Type;
      begin
         Channel.State.Publish (Message, Accepted, Closed_Error, Wake_Count);
         if Closed_Error then
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Failure
              (Future, Aion.Errors.Resource_Closed,
               "broadcast channel is closed", "Aion.Channel.Broadcast.Publish");
         elsif not Accepted then
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Failure
              (Future, Aion.Errors.Runtime_Error,
               "broadcast publish failed", "Aion.Channel.Broadcast.Publish");
         else
            for I in 1 .. Wake_Count loop
               Channel.State.Take_Pending_Wake (I, RF, V, Found);
               if Found and then Message_Futures.Is_Valid (RF) then
                  Ignored_Msg := Message_Futures.Complete_Success (RF, V);
               end if;
            end loop;
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Success (Future, True);
         end if;
         return Future;
      end Publish;

      function Receive
        (Channel    : in out Broadcast_Channel;
         Subscriber : Subscriber_Id;
         Runtime    : access Aion.Runtime.Runtime_Handle := null;
         Name       : String := "broadcast.receive")
         return Message_Futures.Future_Handle is
         pragma Unreferenced (Runtime);
         Future : constant Message_Futures.Future_Handle := Message_Futures.Create (Name => Name);
         Complete, Accepted, Closed_Error : Boolean;
         Value : Message_Type;
         Ignored : Message_Futures.Operation_Results.Result_Type;
      begin
         Channel.State.Receive (Subscriber, Future, Complete, Value, Accepted, Closed_Error);
         if Closed_Error then
            Ignored := Message_Futures.Complete_Failure
              (Future, Aion.Errors.Resource_Closed,
               "broadcast channel is closed", "Aion.Channel.Broadcast.Receive");
         elsif not Accepted then
            Ignored := Message_Futures.Complete_Failure
              (Future, Aion.Errors.Invalid_Argument,
               "invalid broadcast subscriber", "Aion.Channel.Broadcast.Receive");
         elsif Complete then
            Ignored := Message_Futures.Complete_Success (Future, Value);
         end if;
         return Future;
      end Receive;

      function Close
        (Channel : in out Broadcast_Channel;
         Reason  : String := "broadcast channel closed")
         return Aion.Sync.Boolean_Results.Result_Type is
         Count : Natural;
         RF : Message_Futures.Future_Handle;
         V  : Message_Type;
         Found : Boolean;
         Ignored : Message_Futures.Operation_Results.Result_Type;
      begin
         Channel.State.Close_All (Count);
         for I in 1 .. Count loop
            Channel.State.Take_Pending_Wake (I, RF, V, Found);
            if Found and then Message_Futures.Is_Valid (RF) then
               Ignored := Message_Futures.Complete_Failure
                 (RF, Aion.Errors.Resource_Closed, Reason, "Aion.Channel.Broadcast.Close");
            end if;
         end loop;
         return Aion.Sync.Boolean_Results.Success (True);
      end Close;

      function Subscriber_Count_Of (Channel : Broadcast_Channel) return Natural is
      begin
         return Channel.State.Subscribers;
      end Subscriber_Count_Of;

      function Stats_Of (Channel : Broadcast_Channel) return Aion.Channel.Channel_Stats is
      begin
         return Channel.State.Snapshot;
      end Stats_Of;
   end Generic_Broadcast_Channel;
end Aion.Channel.Broadcast;
