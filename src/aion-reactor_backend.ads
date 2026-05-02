--  Backend abstraction for Aion's runtime-owned I/O reactor.
--
--  The current implementation is a portable readiness backend. Native IOCP,
--  epoll, and kqueue bindings can replace the backend internals without
--  changing Aion.Reactor or higher-level networking APIs.

with Aion.Errors;
with Aion.IO_Resource;
with Aion.IO_Token;
with Aion.Platform;
with Aion.Readiness;
with Aion.Result;
with Aion.Types;
with Aion.Waker;

package Aion.Reactor_Backend is

   type Backend_Event is record
      Token  : Aion.IO_Token.IO_Token := Aion.IO_Token.No_Token;
      Ready  : Aion.Readiness.Readiness_Set := Aion.Readiness.None;
      Waker  : Aion.Waker.Waker := Aion.Waker.Noop;
   end record;

   Null_Event : constant Backend_Event :=
     (Token => Aion.IO_Token.No_Token,
      Ready => Aion.Readiness.None,
      Waker => Aion.Waker.Noop);

   type Backend_Stats is record
      Backend              : Aion.Platform.Backend_Kind := Aion.Platform.Backend_Portable_Select;
      Max_Resources        : Natural := 0;
      Registered_Resources : Natural := 0;
      Event_Depth          : Natural := 0;
      Event_Capacity       : Natural := 0;
      Registered_Total     : Natural := 0;
      Unregistered_Total   : Natural := 0;
      Interest_Updates     : Natural := 0;
      Readiness_Queued     : Natural := 0;
      Readiness_Dispatched : Natural := 0;
      Readiness_Dropped    : Natural := 0;
      Worker_Running       : Boolean := False;
      Stop_Requested       : Boolean := False;
   end record;

   type Backend is limited private;
   type Backend_Access is access all Backend;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);

   function Create
     (Max_Resources : Positive;
      Max_Events    : Positive;
      Kind          : Aion.Platform.Backend_Kind := Aion.Platform.Default_Backend)
      return Backend_Access;

   procedure Destroy (Item : in out Backend_Access);

   function Register
     (Item     : not null Backend_Access;
      Token    : Aion.IO_Token.IO_Token;
      Handle   : Aion.IO_Resource.Native_Handle;
      Interest : Aion.Readiness.Readiness_Set;
      Waker    : Aion.Waker.Waker) return Operation_Results.Result_Type;

   function Unregister
     (Item  : not null Backend_Access;
      Token : Aion.IO_Token.IO_Token) return Operation_Results.Result_Type;

   function Update_Interest
     (Item     : not null Backend_Access;
      Token    : Aion.IO_Token.IO_Token;
      Interest : Aion.Readiness.Readiness_Set) return Operation_Results.Result_Type;

   function Notify_Readiness
     (Item  : not null Backend_Access;
      Token : Aion.IO_Token.IO_Token;
      Ready : Aion.Readiness.Readiness_Set) return Operation_Results.Result_Type;

   procedure Wait
     (Item  : in out Backend;
      Event : out Backend_Event;
      Found : out Boolean);

   procedure Request_Stop (Item : in out Backend);
   procedure Mark_Worker_Started (Item : in out Backend);
   procedure Mark_Worker_Stopped (Item : in out Backend);
   procedure Mark_Dispatched (Item : in out Backend);

   function Stats_Of (Item : Backend) return Backend_Stats;
   function Resource_Count_Of (Item : Backend) return Natural;
   function Event_Depth_Of (Item : Backend) return Natural;
   function Is_Stopping (Item : Backend) return Boolean;

   function Image (Event : Backend_Event) return String;
   function Image (Stats : Backend_Stats) return String;

private
   type Registration_Record is record
      Token    : Aion.IO_Token.IO_Token := Aion.IO_Token.No_Token;
      Handle   : Aion.IO_Resource.Native_Handle := Aion.IO_Resource.Invalid_Native_Handle;
      Interest : Aion.Readiness.Readiness_Set := Aion.Readiness.None;
      Waker    : Aion.Waker.Waker := Aion.Waker.Noop;
      State    : Aion.Types.Resource_State := Aion.Types.Resource_Closed;
   end record;

   Null_Registration : constant Registration_Record :=
     (Token    => Aion.IO_Token.No_Token,
      Handle   => Aion.IO_Resource.Invalid_Native_Handle,
      Interest => Aion.Readiness.None,
      Waker    => Aion.Waker.Noop,
      State    => Aion.Types.Resource_Closed);

   type Registration_Array is array (Positive range <>) of Registration_Record;
   type Event_Array is array (Positive range <>) of Backend_Event;

   protected type Backend_State
     (Max_Resources : Positive;
      Max_Events    : Positive) is
      procedure Register
        (Token    : in Aion.IO_Token.IO_Token;
         Handle   : in Aion.IO_Resource.Native_Handle;
         Interest : in Aion.Readiness.Readiness_Set;
         Waker    : in Aion.Waker.Waker;
         Accepted : out Boolean;
         Failure  : out Aion.Errors.Error);

      procedure Unregister
        (Token   : in Aion.IO_Token.IO_Token;
         Removed : out Boolean);

      procedure Update_Interest
        (Token    : in Aion.IO_Token.IO_Token;
         Interest : in Aion.Readiness.Readiness_Set;
         Updated  : out Boolean);

      procedure Notify_Readiness
        (Token    : in Aion.IO_Token.IO_Token;
         Ready    : in Aion.Readiness.Readiness_Set;
         Accepted : out Boolean;
         Failure  : out Aion.Errors.Error);

      entry Wait
        (Event : out Backend_Event;
         Found : out Boolean);

      procedure Request_Stop;
      procedure Mark_Worker_Started;
      procedure Mark_Worker_Stopped;
      procedure Mark_Dispatched;

      function Snapshot return Backend_Stats;
      function Resource_Count return Natural;
      function Event_Depth return Natural;
      function Stopping return Boolean;
   private
      Resources : Registration_Array (1 .. Max_Resources);
      Events    : Event_Array (1 .. Max_Events);

      Resource_Count_Value : Natural := 0;
      Event_Count          : Natural := 0;
      Event_Head           : Positive := 1;
      Event_Tail           : Positive := 1;

      Registered_Total     : Natural := 0;
      Unregistered_Total   : Natural := 0;
      Interest_Updates     : Natural := 0;
      Readiness_Queued     : Natural := 0;
      Readiness_Dispatched : Natural := 0;
      Readiness_Dropped    : Natural := 0;

      Worker_Started : Boolean := False;
      Worker_Stopped : Boolean := False;
      Stop_Requested : Boolean := False;
   end Backend_State;

   type Backend_State_Access is access all Backend_State;

   type Backend is limited record
      Kind  : Aion.Platform.Backend_Kind := Aion.Platform.Backend_Portable_Select;
      State : Backend_State_Access := null;
   end record;

end Aion.Reactor_Backend;
