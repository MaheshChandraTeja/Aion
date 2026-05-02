with Aion.Errors;
package body Aion.Actor is
   package body Generic_Actor is
      use type Interfaces.Unsigned_64;

      protected body Actor_State is
         procedure Mark_Dispatched is
         begin
            Dispatched_Total := Dispatched_Total + 1;
         end Mark_Dispatched;

         procedure Mark_Failed is
         begin
            Failure_Total := Failure_Total + 1;
         end Mark_Failed;

         function Snapshot (Queued : Natural) return Dispatch_Stats is
         begin
            return
              (Queued     => Queued,
               Dispatched => Dispatched_Total,
               Failures   => Failure_Total);
         end Snapshot;
      end Actor_State;

      function Send
        (Mailbox : in out Actor_Mailbox;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "actor.send")
         return Aion.Sync.Boolean_Futures.Future_Handle is
      begin
         return Mailbox_Channel.Send (Mailbox.Queue, Message, Runtime, Name);
      end Send;

      function Dispatch_One
        (Mailbox : in out Actor_Mailbox) return Aion.Sync.Boolean_Results.Result_Type is
         Item : constant Mailbox_Channel.Message_Results.Result_Type :=
           Mailbox_Channel.Try_Receive (Mailbox.Queue);
      begin
         if Mailbox_Channel.Message_Results.Is_Ok (Item) then
            Handle (Mailbox_Channel.Message_Results.Value (Item));
            Mailbox.State.Mark_Dispatched;
            return Aion.Sync.Boolean_Results.Success (True);
         else
            Mailbox.State.Mark_Failed;
            return Aion.Sync.Boolean_Results.Failure
              (Mailbox_Channel.Message_Results.Error (Item));
         end if;
      exception
         when others =>
            Mailbox.State.Mark_Failed;
            return Aion.Sync.Boolean_Results.Failure
              (Aion.Errors.Runtime_Error,
               "actor handler raised an exception", "Aion.Actor.Dispatch_One");
      end Dispatch_One;

      function Drain
        (Mailbox : in out Actor_Mailbox;
         Limit   : Natural := Natural'Last) return Aion.Sync.Boolean_Results.Result_Type is
         Count : Natural := 0;
         Result : Aion.Sync.Boolean_Results.Result_Type :=
           Aion.Sync.Boolean_Results.Success (True);
      begin
         while Count < Limit and then Mailbox_Channel.Buffered_Count_Of (Mailbox.Queue) > 0 loop
            Result := Dispatch_One (Mailbox);
            exit when Aion.Sync.Boolean_Results.Is_Err (Result);
            Count := Count + 1;
         end loop;
         return Result;
      end Drain;

      function Close
        (Mailbox : in out Actor_Mailbox;
         Reason  : String := "actor mailbox closed") return Aion.Sync.Boolean_Results.Result_Type is
      begin
         return Mailbox_Channel.Close (Mailbox.Queue, Reason);
      end Close;

      function Stats_Of (Mailbox : Actor_Mailbox) return Dispatch_Stats is
      begin
         return Mailbox.State.Snapshot (Mailbox_Channel.Buffered_Count_Of (Mailbox.Queue));
      end Stats_Of;

      function Channel_Stats_Of (Mailbox : Actor_Mailbox) return Aion.Channel.Channel_Stats is
      begin
         return Mailbox_Channel.Stats_Of (Mailbox.Queue);
      end Channel_Stats_Of;
   end Generic_Actor;
end Aion.Actor;
