--  Aion.Net root package.
--
--  Shared network payloads, result/future instantiations, and GNAT.Sockets
--  initialization helpers used by TCP and UDP modules. Module 6 deliberately
--  exposes one bounded buffer type so futures remain definite, copy-safe, and
--  generic-friendly across Ada compilers.

with Ada.Streams;
with Aion.Errors;
with Aion.Future;
with Aion.Result;

package Aion.Net is
   pragma Elaborate_Body;

   Max_Buffer_Size : constant := 65_536;

   subtype Buffer_Length is Natural range 0 .. Max_Buffer_Size;
   subtype Buffer_Index is Ada.Streams.Stream_Element_Offset
     range 1 .. Ada.Streams.Stream_Element_Offset (Max_Buffer_Size);

   type Net_Buffer is record
      Length : Buffer_Length := 0;
      Data   : Ada.Streams.Stream_Element_Array (Buffer_Index) := (others => 0);
   end record;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);
   package Count_Results is new Aion.Result.Generic_Result (Natural);
   package Buffer_Results is new Aion.Result.Generic_Result (Net_Buffer);

   package Count_Futures is new Aion.Future.Generic_Future (Natural);
   package Buffer_Futures is new Aion.Future.Generic_Future (Net_Buffer);

   function Empty_Buffer return Net_Buffer;

   function From_String (Value : String) return Net_Buffer;
   function To_String (Buffer : Net_Buffer) return String;

   function From_Stream
     (Value : Ada.Streams.Stream_Element_Array) return Net_Buffer;

   procedure To_Stream
     (Buffer : Net_Buffer;
      Target : out Ada.Streams.Stream_Element_Array;
      Last   : out Ada.Streams.Stream_Element_Offset);

   function Length_Of (Buffer : Net_Buffer) return Buffer_Length;
   function Is_Empty (Buffer : Net_Buffer) return Boolean;
   function Image (Buffer : Net_Buffer) return String;

   procedure Initialize;
   procedure Finalize;
   function Is_Initialized return Boolean;

   function Failure
     (Code    : Aion.Errors.Error_Code;
      Message : String;
      Origin  : String := "Aion.Net") return Operation_Results.Result_Type;

private
   protected Network_State is
      procedure Mark_Initialized;
      procedure Mark_Finalized;
      function Ready return Boolean;
   private
      Initialized : Boolean := False;
   end Network_State;
end Aion.Net;
