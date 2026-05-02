with Aion.Errors;

package body Aion.Channel.Watch is
   package body Generic_Watch_Channel is
      use type Interfaces.Unsigned_64;

      protected body Watch_State is
         procedure Initialize (Initial : in Message_Type) is
         begin
            Latest := Initial;
            Initialized := True;
            Version := 1;
         end Initialize;

         procedure Subscribe (Id : out Subscriber_Id; Accepted : out Boolean) is
         begin
            Id := No_Subscriber;
            Accepted := False;
            if Closed_Flag or else not Initialized then
               Failure_Total := Failure_Total + 1;
               return;
            end if;
            for I in Active'Range loop
               if not Active (I) then
                  Active (I) := True;
                  Last_Seen (I) := 0;
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
               Closed_Error := True;
               Failure_Total := Failure_Total + 1;
               return;
            end if;

            Latest := Message;
            Initialized := True;
            Version := Version + 1;
            Sent_Total := Sent_Total + 1;

            for I in Active'Range loop
               if Active (I) and then Waiting (I) then
                  Pending_Count := Pending_Count + 1;
                  Pending_Futures (Pending_Count) := Waiters (I);
                  Pending_Values (Pending_Count) := Latest;
                  Waiters (I) := Message_Futures.Null_Future;
                  Waiting (I) := False;
                  Last_Seen (I) := Version;
                  Wake_Count := Wake_Count + 1;
                  Wake_Total := Wake_Total + 1;
                  Received_Total := Received_Total + 1;
               end if;
            end loop;

            Accepted := True;
         end Publish;

         procedure Take_Pending_Wake
           (Index : in Positive;
            Future : out Message_Futures.Future_Handle;
            Value : out Message_Type;
            Found : out Boolean) is
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

         procedure Receive_Changed
           (Id : in Subscriber_Id;
            Future : in Message_Futures.Future_Handle;
            Complete : out Boolean;
            Value : out Message_Type;
            Accepted : out Boolean;
            Closed_Error : out Boolean) is
            I : constant Natural := Natural (Id);
         begin
            Complete := False;
            Accepted := False;
            Closed_Error := False;

            if not Initialized then
               Failure_Total := Failure_Total + 1;
               return;
            elsif not (I in Active'Range) or else not Active (I) then
               Failure_Total := Failure_Total + 1;
               return;
            elsif Last_Seen (I) < Version then
               Value := Latest;
               Last_Seen (I) := Version;
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
         end Receive_Changed;

         procedure Read_Current
           (Found : out Boolean;
            Value : out Message_Type;
            Closed_Error : out Boolean) is
         begin
            Found := Initialized;
            Closed_Error := Closed_Flag;
            if Initialized then
               Value := Latest;
            else
               Failure_Total := Failure_Total + 1;
            end if;
         end Read_Current;

         procedure Close_All (Wake_Count : out Natural) is
         begin
            Closed_Flag := True;
            Wake_Count := 0;
            Pending_Count := 0;
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

         function Snapshot return Aion.Channel.Channel_Stats is
            Waiting_Total : Natural := 0;
         begin
            for I in Active'Range loop
               if Active (I) and then Waiting (I) then
                  Waiting_Total := Waiting_Total + 1;
               end if;
            end loop;
            return
              (Buffered          => (if Initialized then 1 else 0),
               Capacity          => 1,
               Waiting_Senders   => 0,
               Waiting_Receivers => Waiting_Total,
               Sent              => Sent_Total,
               Received          => Received_Total,
               Wakeups           => Wake_Total,
               Dropped           => 0,
               Closed            => Closed_Flag,
               Failures          => Failure_Total);
         end Snapshot;
      end Watch_State;

      procedure Initialize
        (Channel : in out Watch_Channel;
         Initial : Message_Type) is
      begin
         Channel.State.Initialize (Initial);
      end Initialize;

      function Subscribe
        (Channel : in out Watch_Channel) return Subscriber_Results.Result_Type is
         Id : Subscriber_Id;
         Accepted : Boolean;
      begin
         Channel.State.Subscribe (Id, Accepted);
         if Accepted then
            return Subscriber_Results.Success (Id);
         end if;
         return Subscriber_Results.Failure
           (Aion.Errors.Invalid_State,
            "watch channel is not initialized, closed, or full", "Aion.Channel.Watch.Subscribe");
      end Subscribe;

      function Publish
        (Channel : in out Watch_Channel;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "watch.publish")
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
               "watch channel is closed", "Aion.Channel.Watch.Publish");
         elsif not Accepted then
            Ignored_Bool := Aion.Sync.Boolean_Futures.Complete_Failure
              (Future, Aion.Errors.Runtime_Error,
               "watch publish failed", "Aion.Channel.Watch.Publish");
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

      function Receive_Changed
        (Channel    : in out Watch_Channel;
         Subscriber : Subscriber_Id;
         Runtime    : access Aion.Runtime.Runtime_Handle := null;
         Name       : String := "watch.changed")
         return Message_Futures.Future_Handle is
         pragma Unreferenced (Runtime);
         Future : constant Message_Futures.Future_Handle := Message_Futures.Create (Name => Name);
         Complete, Accepted, Closed_Error : Boolean;
         Value : Message_Type;
         Ignored : Message_Futures.Operation_Results.Result_Type;
      begin
         Channel.State.Receive_Changed (Subscriber, Future, Complete, Value, Accepted, Closed_Error);
         if Closed_Error then
            Ignored := Message_Futures.Complete_Failure
              (Future, Aion.Errors.Resource_Closed,
               "watch channel is closed", "Aion.Channel.Watch.Receive_Changed");
         elsif not Accepted then
            Ignored := Message_Futures.Complete_Failure
              (Future, Aion.Errors.Invalid_Argument,
               "invalid watch subscriber or duplicate pending receive", "Aion.Channel.Watch.Receive_Changed");
         elsif Complete then
            Ignored := Message_Futures.Complete_Success (Future, Value);
         end if;
         return Future;
      end Receive_Changed;

      function Current
        (Channel : in out Watch_Channel) return Message_Results.Result_Type is
         Found, Closed_Error : Boolean;
         Value : Message_Type;
      begin
         Channel.State.Read_Current (Found, Value, Closed_Error);
         if Found then
            return Message_Results.Success (Value);
         elsif Closed_Error then
            return Message_Results.Failure
              (Aion.Errors.Resource_Closed,
               "watch channel is closed", "Aion.Channel.Watch.Current");
         else
            return Message_Results.Failure
              (Aion.Errors.Invalid_State,
               "watch channel is not initialized", "Aion.Channel.Watch.Current");
         end if;
      end Current;

      function Close
        (Channel : in out Watch_Channel;
         Reason  : String := "watch channel closed")
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
                 (RF, Aion.Errors.Resource_Closed, Reason, "Aion.Channel.Watch.Close");
            end if;
         end loop;
         return Aion.Sync.Boolean_Results.Success (True);
      end Close;

      function Stats_Of (Channel : Watch_Channel) return Aion.Channel.Channel_Stats is
      begin
         return Channel.State.Snapshot;
      end Stats_Of;
   end Generic_Watch_Channel;
end Aion.Channel.Watch;
