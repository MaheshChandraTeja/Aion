--  Practical unbounded channel facade.
--
--  Internally this uses the bounded channel engine with a high-watermark safety
--  cap. That keeps memory growth explicit and observable while preserving the
--  no-backpressure ergonomics expected from an unbounded channel.

with Aion.Channel.Bounded;
with Aion.Runtime;
with Aion.Sync;

package Aion.Channel.Unbounded is
   generic
      type Message_Type is private;
   package Generic_Unbounded_Channel is
      package Impl is new Aion.Channel.Bounded.Generic_Bounded_Channel (Message_Type);
      package Message_Futures renames Impl.Message_Futures;
      package Message_Results renames Impl.Message_Results;

      type Unbounded_Channel
        (High_Watermark : Positive := 65_536;
         Max_Waiters    : Positive := 4_096) is limited private;

      function Send
        (Channel : in out Unbounded_Channel;
         Message : Message_Type;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "unbounded.send")
         return Aion.Sync.Boolean_Futures.Future_Handle;

      function Try_Send
        (Channel : in out Unbounded_Channel;
         Message : Message_Type) return Aion.Sync.Boolean_Results.Result_Type;

      function Receive
        (Channel : in out Unbounded_Channel;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "unbounded.receive")
         return Message_Futures.Future_Handle;

      function Try_Receive
        (Channel : in out Unbounded_Channel) return Message_Results.Result_Type;

      function Close
        (Channel : in out Unbounded_Channel;
         Reason  : String := "unbounded channel closed")
         return Aion.Sync.Boolean_Results.Result_Type;

      function Is_Closed (Channel : Unbounded_Channel) return Boolean;
      function Buffered_Count_Of (Channel : Unbounded_Channel) return Natural;
      function Stats_Of (Channel : Unbounded_Channel) return Aion.Channel.Channel_Stats;

   private
      type Unbounded_Channel
        (High_Watermark : Positive := 65_536;
         Max_Waiters    : Positive := 4_096) is limited record
         Inner : Impl.Bounded_Channel
           (Capacity => High_Watermark,
            Max_Waiters => Max_Waiters);
      end record;
   end Generic_Unbounded_Channel;
end Aion.Channel.Unbounded;
