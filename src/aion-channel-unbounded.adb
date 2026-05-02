package body Aion.Channel.Unbounded is
   package body Generic_Unbounded_Channel is
      function Send
        (Channel : in out Unbounded_Channel;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "unbounded.send")
         return Aion.Sync.Boolean_Futures.Future_Handle is
      begin
         return Impl.Send (Channel.Inner, Message, Runtime, Name);
      end Send;

      function Try_Send
        (Channel : in out Unbounded_Channel;
         Message : Message_Type) return Aion.Sync.Boolean_Results.Result_Type is
      begin
         return Impl.Try_Send (Channel.Inner, Message);
      end Try_Send;

      function Receive
        (Channel : in out Unbounded_Channel;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "unbounded.receive")
         return Message_Futures.Future_Handle is
      begin
         return Impl.Receive (Channel.Inner, Runtime, Name);
      end Receive;

      function Try_Receive
        (Channel : in out Unbounded_Channel) return Message_Results.Result_Type is
      begin
         return Impl.Try_Receive (Channel.Inner);
      end Try_Receive;

      function Close
        (Channel : in out Unbounded_Channel;
         Reason  : String := "unbounded channel closed")
         return Aion.Sync.Boolean_Results.Result_Type is
      begin
         return Impl.Close (Channel.Inner, Reason);
      end Close;

      function Is_Closed (Channel : Unbounded_Channel) return Boolean is
      begin
         return Impl.Is_Closed (Channel.Inner);
      end Is_Closed;

      function Buffered_Count_Of (Channel : Unbounded_Channel) return Natural is
      begin
         return Impl.Buffered_Count_Of (Channel.Inner);
      end Buffered_Count_Of;

      function Stats_Of (Channel : Unbounded_Channel) return Aion.Channel.Channel_Stats is
      begin
         return Impl.Stats_Of (Channel.Inner);
      end Stats_Of;
   end Generic_Unbounded_Channel;
end Aion.Channel.Unbounded;
