with Ada.Strings.Fixed;

package body Aion.Net is
   use type Ada.Streams.Stream_Element_Offset;

   protected body Network_State is
      procedure Mark_Initialized is
      begin
         Initialized := True;
      end Mark_Initialized;

      procedure Mark_Finalized is
      begin
         Initialized := False;
      end Mark_Finalized;

      function Ready return Boolean is
      begin
         return Initialized;
      end Ready;
   end Network_State;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function Empty_Buffer return Net_Buffer is
   begin
      return (Length => 0, Data => (others => 0));
   end Empty_Buffer;

   function From_String (Value : String) return Net_Buffer is
      Buffer : Net_Buffer := Empty_Buffer;
      Limit  : constant Natural := Natural'Min (Value'Length, Max_Buffer_Size);
      Cursor : Ada.Streams.Stream_Element_Offset := Buffer_Index'First;
   begin
      Buffer.Length := Limit;
      for I in 1 .. Limit loop
         Buffer.Data (Cursor) := Ada.Streams.Stream_Element (Character'Pos (Value (Value'First + I - 1)));
         Cursor := Cursor + 1;
      end loop;
      return Buffer;
   end From_String;

   function To_String (Buffer : Net_Buffer) return String is
      Result : String (1 .. Buffer.Length);
      Cursor : Ada.Streams.Stream_Element_Offset := Buffer_Index'First;
   begin
      if Buffer.Length = 0 then
         return "";
      end if;

      for I in Result'Range loop
         Result (I) := Character'Val (Integer (Buffer.Data (Cursor)) mod 256);
         Cursor := Cursor + 1;
      end loop;
      return Result;
   end To_String;

   function From_Stream
     (Value : Ada.Streams.Stream_Element_Array) return Net_Buffer is
      Buffer : Net_Buffer := Empty_Buffer;
      Limit  : constant Natural := Natural'Min (Value'Length, Max_Buffer_Size);
      Target : Ada.Streams.Stream_Element_Offset := Buffer_Index'First;
      Source : Ada.Streams.Stream_Element_Offset := Value'First;
   begin
      Buffer.Length := Limit;
      for I in 1 .. Limit loop
         Buffer.Data (Target) := Value (Source);
         Target := Target + 1;
         Source := Source + 1;
      end loop;
      return Buffer;
   end From_Stream;

   procedure To_Stream
     (Buffer : Net_Buffer;
      Target : out Ada.Streams.Stream_Element_Array;
      Last   : out Ada.Streams.Stream_Element_Offset) is
      Count  : constant Natural := Natural'Min (Buffer.Length, Target'Length);
      Source : Ada.Streams.Stream_Element_Offset := Buffer_Index'First;
      Dest   : Ada.Streams.Stream_Element_Offset := Target'First;
   begin
      if Count = 0 then
         Last := Target'First - 1;
         return;
      end if;

      for I in 1 .. Count loop
         Target (Dest) := Buffer.Data (Source);
         Source := Source + 1;
         Dest := Dest + 1;
      end loop;
      Last := Target'First + Ada.Streams.Stream_Element_Offset (Count) - 1;
   end To_Stream;

   function Length_Of (Buffer : Net_Buffer) return Buffer_Length is
   begin
      return Buffer.Length;
   end Length_Of;

   function Is_Empty (Buffer : Net_Buffer) return Boolean is
   begin
      return Buffer.Length = 0;
   end Is_Empty;

   function Image (Buffer : Net_Buffer) return String is
   begin
      return "Net_Buffer(length=" & Trim (Natural'Image (Buffer.Length)) & ")";
   end Image;

   procedure Initialize is
   begin
      if not Network_State.Ready then
         Network_State.Mark_Initialized;
      end if;
   end Initialize;

   procedure Finalize is
   begin
      if Network_State.Ready then
         Network_State.Mark_Finalized;
      end if;
   end Finalize;

   function Is_Initialized return Boolean is
   begin
      return Network_State.Ready;
   end Is_Initialized;

   function Failure
     (Code    : Aion.Errors.Error_Code;
      Message : String;
      Origin  : String := "Aion.Net") return Operation_Results.Result_Type is
   begin
      return Operation_Results.Failure (Code, Message, Origin);
   end Failure;

end Aion.Net;
