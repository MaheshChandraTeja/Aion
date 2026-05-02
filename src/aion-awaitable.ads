--  Awaitable facade over Future.
--
--  This gives later modules a stable abstraction for values that can be waited
--  on, while the actual state and completion logic remain owned by Future.

with Ada.Strings.Unbounded;
with Aion.Completion;
with Aion.Future;
with Aion.Types;
with Aion.Waker;

package Aion.Awaitable is

   generic
      with package Futures is new Aion.Future.Generic_Future (<>);
   package Generic_Awaitable is
      type Awaitable_Handle is private;

      Null_Awaitable : constant Awaitable_Handle;

      function From_Future
        (Future : Futures.Future_Handle;
         Name   : String := "") return Awaitable_Handle;

      function Future_Of
        (Awaitable : Awaitable_Handle) return Futures.Future_Handle;

      function Is_Valid (Awaitable : Awaitable_Handle) return Boolean;
      function State_Of
        (Awaitable : Awaitable_Handle) return Aion.Completion.Completion_State;
      function Is_Ready (Awaitable : Awaitable_Handle) return Boolean;
      function Is_Done (Awaitable : Awaitable_Handle) return Boolean;

      function Await
        (Awaitable : Awaitable_Handle) return Futures.Value_Results.Result_Type;

      function Await_Timeout
        (Awaitable : Awaitable_Handle;
         Timeout   : Aion.Types.Milliseconds)
         return Futures.Value_Results.Result_Type;

      function Attach_Waker
        (Awaitable : Awaitable_Handle;
         Waker     : Aion.Waker.Waker)
         return Futures.Operation_Results.Result_Type;

      function Image (Awaitable : Awaitable_Handle) return String;

   private
      package US renames Ada.Strings.Unbounded;

      type Awaitable_Handle is record
         Name   : US.Unbounded_String := US.Null_Unbounded_String;
         Future : Futures.Future_Handle := Futures.Null_Future;
      end record;

      Null_Awaitable : constant Awaitable_Handle :=
        (Name   => US.Null_Unbounded_String,
         Future => Futures.Null_Future);
   end Generic_Awaitable;

end Aion.Awaitable;
