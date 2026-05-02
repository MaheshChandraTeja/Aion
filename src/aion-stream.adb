package body Aion.Stream is
   package body Generic_Stream is
      function Push
        (Stream  : in out Async_Stream;
         Item    : Item_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "stream.push")
         return Aion.Sync.Boolean_Futures.Future_Handle is
      begin
         return Queue.Send (Stream.Items, Item, Runtime, Name);
      end Push;

      function Next
        (Stream  : in out Async_Stream;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "stream.next")
         return Item_Futures.Future_Handle is
      begin
         return Queue.Receive (Stream.Items, Runtime, Name);
      end Next;

      function Close
        (Stream : in out Async_Stream;
         Reason : String := "stream closed") return Aion.Sync.Boolean_Results.Result_Type is
      begin
         return Queue.Close (Stream.Items, Reason);
      end Close;

      function Stats_Of (Stream : Async_Stream) return Aion.Channel.Channel_Stats is
      begin
         return Queue.Stats_Of (Stream.Items);
      end Stats_Of;
   end Generic_Stream;
end Aion.Stream;
