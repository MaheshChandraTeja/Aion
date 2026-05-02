--  Lightweight runtime tracing for Aion.
--
--  The default trace buffer is a protected ring buffer. It is intentionally
--  global, bounded, and resettable so production users can enable diagnostics
--  without creating unbounded memory growth.

with Ada.Calendar;
with Interfaces;

package Aion.Tracing is
   pragma Elaborate_Body;

   type Span_Id is new Interfaces.Unsigned_64;
   No_Span : constant Span_Id := 0;

   Max_Name_Length      : constant Positive := 128;
   Max_Component_Length : constant Positive := 64;
   Default_Buffer_Size  : constant Positive := 4_096;

   type Trace_Event_Kind is
     (Trace_Span_Start,
      Trace_Span_End,
      Trace_Event,
      Trace_Error);

   type Trace_Event_Record is record
      Id            : Span_Id := No_Span;
      Parent        : Span_Id := No_Span;
      Kind          : Trace_Event_Kind := Trace_Event;
      Component     : String (1 .. Max_Component_Length) := (others => ' ');
      Component_Len : Natural := 0;
      Name          : String (1 .. Max_Name_Length) := (others => ' ');
      Name_Len      : Natural := 0;
      At_Time       : Ada.Calendar.Time := Ada.Calendar.Time_Of (1901, 1, 1);
   end record;

   type Trace_Stats is record
      Capacity : Natural := Default_Buffer_Size;
      Stored   : Natural := 0;
      Written  : Interfaces.Unsigned_64 := 0;
      Dropped  : Interfaces.Unsigned_64 := 0;
   end record;

   function Start_Span
     (Name      : String;
      Component : String := "runtime";
      Parent    : Span_Id := No_Span) return Span_Id;

   procedure Finish_Span
     (Id        : Span_Id;
      Name      : String := "";
      Component : String := "runtime");

   procedure Record_Event
     (Name      : String;
      Component : String := "runtime";
      Parent    : Span_Id := No_Span);

   procedure Record_Error
     (Name      : String;
      Component : String := "runtime";
      Parent    : Span_Id := No_Span);

   procedure Clear;

   function Count return Natural;
   function Stats return Trace_Stats;
   function Event_At (Index : Positive) return Trace_Event_Record;
   function Image (Kind : Trace_Event_Kind) return String;
   function Image (Event : Trace_Event_Record) return String;
   function Image (Stats : Trace_Stats) return String;
end Aion.Tracing;
