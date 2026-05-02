--  Async stream abstraction backed by a cooperative queue.

with Aion.Channel;
with Aion.Channel.Unbounded;
with Aion.Runtime;
with Aion.Sync;

package Aion.Stream is
   generic
      type Item_Type is private;
   package Generic_Stream is
      package Queue is new Aion.Channel.Unbounded.Generic_Unbounded_Channel (Item_Type);
      package Item_Futures renames Queue.Message_Futures;
      package Item_Results renames Queue.Message_Results;

      type Async_Stream
        (High_Watermark : Positive := 65_536;
         Max_Waiters    : Positive := 4_096) is limited private;

      function Push
        (Stream  : in out Async_Stream;
         Item    : Item_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "stream.push")
         return Aion.Sync.Boolean_Futures.Future_Handle;

      function Next
        (Stream  : in out Async_Stream;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "stream.next")
         return Item_Futures.Future_Handle;

      function Close
        (Stream : in out Async_Stream;
         Reason : String := "stream closed") return Aion.Sync.Boolean_Results.Result_Type;

      function Stats_Of (Stream : Async_Stream) return Aion.Channel.Channel_Stats;

   private
      type Async_Stream
        (High_Watermark : Positive := 65_536;
         Max_Waiters    : Positive := 4_096) is limited record
         Items : Queue.Unbounded_Channel (High_Watermark, Max_Waiters);
      end record;
   end Generic_Stream;
end Aion.Stream;
