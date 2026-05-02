--  Common channel types, stats, and boolean futures for Aion communication
--  primitives. Concrete channel implementations live in child packages.

with Interfaces;
with Aion.Sync;

package Aion.Channel is
   type Channel_Status is (Channel_Open, Channel_Closed);

   type Channel_Stats is record
      Buffered          : Natural := 0;
      Capacity          : Natural := 0;
      Waiting_Senders   : Natural := 0;
      Waiting_Receivers : Natural := 0;
      Sent              : Interfaces.Unsigned_64 := 0;
      Received          : Interfaces.Unsigned_64 := 0;
      Wakeups           : Interfaces.Unsigned_64 := 0;
      Dropped           : Interfaces.Unsigned_64 := 0;
      Closed            : Boolean := False;
      Failures          : Interfaces.Unsigned_64 := 0;
   end record;

   subtype Boolean_Future is Aion.Sync.Boolean_Futures.Future_Handle;
   subtype Boolean_Result is Aion.Sync.Boolean_Results.Result_Type;

   function Image (Status : Channel_Status) return String;
   function Image (Stats : Channel_Stats) return String;
end Aion.Channel;
