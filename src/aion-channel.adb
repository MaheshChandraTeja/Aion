with Ada.Strings.Fixed;

package body Aion.Channel is
   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function U64_Image (Value : Interfaces.Unsigned_64) return String is
   begin
      return Trim (Interfaces.Unsigned_64'Image (Value));
   end U64_Image;

   function Nat_Image (Value : Natural) return String is
   begin
      return Trim (Natural'Image (Value));
   end Nat_Image;

   function Image (Status : Channel_Status) return String is
   begin
      case Status is
         when Channel_Open   => return "open";
         when Channel_Closed => return "closed";
      end case;
   end Image;

   function Image (Stats : Channel_Stats) return String is
   begin
      return
        "channel[buffered=" & Nat_Image (Stats.Buffered) &
        ",capacity=" & Nat_Image (Stats.Capacity) &
        ",waiting_senders=" & Nat_Image (Stats.Waiting_Senders) &
        ",waiting_receivers=" & Nat_Image (Stats.Waiting_Receivers) &
        ",sent=" & U64_Image (Stats.Sent) &
        ",received=" & U64_Image (Stats.Received) &
        ",wakeups=" & U64_Image (Stats.Wakeups) &
        ",dropped=" & U64_Image (Stats.Dropped) &
        ",closed=" & Boolean'Image (Stats.Closed) &
        ",failures=" & U64_Image (Stats.Failures) & "]";
   end Image;
end Aion.Channel;
