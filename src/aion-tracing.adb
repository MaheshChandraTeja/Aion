with Ada.Strings.Fixed;

package body Aion.Tracing is
   use type Interfaces.Unsigned_64;

   type Event_Array is array (Positive range <>) of Trace_Event_Record;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function U64_Image (Value : Interfaces.Unsigned_64) return String is
   begin
      return Trim (Interfaces.Unsigned_64'Image (Value));
   end U64_Image;

   function Natural_Image (Value : Natural) return String is
   begin
      return Trim (Natural'Image (Value));
   end Natural_Image;

   procedure Store_Text
     (Source : String;
      Target : out String;
      Length : out Natural) is
      Last : constant Natural := Natural'Min (Source'Length, Target'Length);
   begin
      Target := (others => ' ');
      Length := Last;
      if Last > 0 then
         Target (Target'First .. Target'First + Last - 1) :=
           Source (Source'First .. Source'First + Last - 1);
      end if;
   end Store_Text;

   function Build_Event
     (Id        : Span_Id;
      Parent    : Span_Id;
      Kind      : Trace_Event_Kind;
      Component : String;
      Name      : String) return Trace_Event_Record is
      Event : Trace_Event_Record;
   begin
      Event.Id := Id;
      Event.Parent := Parent;
      Event.Kind := Kind;
      Event.At_Time := Ada.Calendar.Clock;
      Store_Text (Component, Event.Component, Event.Component_Len);
      Store_Text (Name, Event.Name, Event.Name_Len);
      return Event;
   end Build_Event;

   protected Trace_Buffer is
      procedure Next_Id (Id : out Span_Id);
      procedure Push (Event : in Trace_Event_Record);
      procedure Clear;
      function Count return Natural;
      function Snapshot return Trace_Stats;
      function Event_At (Index : Positive) return Trace_Event_Record;
   private
      Buffer : Event_Array (1 .. Default_Buffer_Size);
      Head   : Positive := 1;
      Stored_Count : Natural := 0;
      Written_Total : Interfaces.Unsigned_64 := 0;
      Dropped_Total : Interfaces.Unsigned_64 := 0;
      Current_Id : Span_Id := 1;
   end Trace_Buffer;

   protected body Trace_Buffer is
      procedure Next_Id (Id : out Span_Id) is
      begin
         Id := Current_Id;
         if Current_Id = Span_Id'Last then
            Current_Id := 1;
         else
            Current_Id := Current_Id + 1;
         end if;
      end Next_Id;

      procedure Push (Event : in Trace_Event_Record) is
      begin
         Buffer (Head) := Event;

         if Head = Default_Buffer_Size then
            Head := 1;
         else
            Head := Head + 1;
         end if;

         if Stored_Count < Default_Buffer_Size then
            Stored_Count := Stored_Count + 1;
         else
            Dropped_Total := Dropped_Total + 1;
         end if;

         Written_Total := Written_Total + 1;
      end Push;

      procedure Clear is
      begin
         Head := 1;
         Stored_Count := 0;
         Written_Total := 0;
         Dropped_Total := 0;
      end Clear;

      function Count return Natural is
      begin
         return Stored_Count;
      end Count;

      function Snapshot return Trace_Stats is
      begin
         return
           (Capacity => Default_Buffer_Size,
            Stored => Stored_Count,
            Written => Written_Total,
            Dropped => Dropped_Total);
      end Snapshot;

      function Event_At (Index : Positive) return Trace_Event_Record is
         Position : Natural;
      begin
         if Index > Stored_Count then
            return Build_Event (No_Span, No_Span, Trace_Error, "tracing", "index out of range");
         end if;

         if Stored_Count < Default_Buffer_Size then
            Position := Index;
         else
            Position := Head + Index - 1;
            while Position > Default_Buffer_Size loop
               Position := Position - Default_Buffer_Size;
            end loop;
         end if;

         return Buffer (Positive (Position));
      end Event_At;
   end Trace_Buffer;

   function Start_Span
     (Name      : String;
      Component : String := "runtime";
      Parent    : Span_Id := No_Span) return Span_Id is
      Id : Span_Id;
   begin
      Trace_Buffer.Next_Id (Id);
      Trace_Buffer.Push (Build_Event (Id, Parent, Trace_Span_Start, Component, Name));
      return Id;
   end Start_Span;

   procedure Finish_Span
     (Id        : Span_Id;
      Name      : String := "";
      Component : String := "runtime") is
      Actual_Name : constant String := (if Name'Length = 0 then "span" else Name);
   begin
      Trace_Buffer.Push (Build_Event (Id, No_Span, Trace_Span_End, Component, Actual_Name));
   end Finish_Span;

   procedure Record_Event
     (Name      : String;
      Component : String := "runtime";
      Parent    : Span_Id := No_Span) is
   begin
      Trace_Buffer.Push (Build_Event (No_Span, Parent, Trace_Event, Component, Name));
   end Record_Event;

   procedure Record_Error
     (Name      : String;
      Component : String := "runtime";
      Parent    : Span_Id := No_Span) is
   begin
      Trace_Buffer.Push (Build_Event (No_Span, Parent, Trace_Error, Component, Name));
   end Record_Error;

   procedure Clear is
   begin
      Trace_Buffer.Clear;
   end Clear;

   function Count return Natural is
   begin
      return Trace_Buffer.Count;
   end Count;

   function Stats return Trace_Stats is
   begin
      return Trace_Buffer.Snapshot;
   end Stats;

   function Event_At (Index : Positive) return Trace_Event_Record is
   begin
      return Trace_Buffer.Event_At (Index);
   end Event_At;

   function Image (Kind : Trace_Event_Kind) return String is
   begin
      case Kind is
         when Trace_Span_Start => return "span-start";
         when Trace_Span_End => return "span-end";
         when Trace_Event => return "event";
         when Trace_Error => return "error";
      end case;
   end Image;

   function Image (Event : Trace_Event_Record) return String is
   begin
      return "Trace_Event(kind=" & Image (Event.Kind) &
        ", component=" & Event.Component (1 .. Natural'Max (1, Event.Component_Len)) &
        ", name=" & Event.Name (1 .. Natural'Max (1, Event.Name_Len)) & ")";
   end Image;

   function Image (Stats : Trace_Stats) return String is
   begin
      return "Trace_Stats(capacity=" & Natural_Image (Stats.Capacity) &
        ", stored=" & Natural_Image (Stats.Stored) &
        ", written=" & U64_Image (Stats.Written) &
        ", dropped=" & U64_Image (Stats.Dropped) & ")";
   end Image;
end Aion.Tracing;
