package body Aion.Awaitable is

   package body Generic_Awaitable is

      function From_Future
        (Future : Futures.Future_Handle;
         Name   : String := "") return Awaitable_Handle is
      begin
         return
           (Name   => US.To_Unbounded_String (Name),
            Future => Future);
      end From_Future;

      function Future_Of
        (Awaitable : Awaitable_Handle) return Futures.Future_Handle is
      begin
         return Awaitable.Future;
      end Future_Of;

      function Is_Valid (Awaitable : Awaitable_Handle) return Boolean is
      begin
         return Futures.Is_Valid (Awaitable.Future);
      end Is_Valid;

      function State_Of
        (Awaitable : Awaitable_Handle) return Aion.Completion.Completion_State is
      begin
         return Futures.State_Of (Awaitable.Future);
      end State_Of;

      function Is_Ready (Awaitable : Awaitable_Handle) return Boolean is
      begin
         return Futures.Is_Ready (Awaitable.Future);
      end Is_Ready;

      function Is_Done (Awaitable : Awaitable_Handle) return Boolean is
      begin
         return Futures.Is_Done (Awaitable.Future);
      end Is_Done;

      function Await
        (Awaitable : Awaitable_Handle) return Futures.Value_Results.Result_Type is
      begin
         return Futures.Await (Awaitable.Future);
      end Await;

      function Await_Timeout
        (Awaitable : Awaitable_Handle;
         Timeout   : Aion.Types.Milliseconds)
         return Futures.Value_Results.Result_Type is
      begin
         return Futures.Await_Timeout (Awaitable.Future, Timeout);
      end Await_Timeout;

      function Attach_Waker
        (Awaitable : Awaitable_Handle;
         Waker     : Aion.Waker.Waker)
         return Futures.Operation_Results.Result_Type is
      begin
         return Futures.Attach_Waker (Awaitable.Future, Waker);
      end Attach_Waker;

      function Image (Awaitable : Awaitable_Handle) return String is
      begin
         return
           "awaitable[name=" & US.To_String (Awaitable.Name) &
           "," & Futures.Image (Awaitable.Future) & "]";
      end Image;

   end Generic_Awaitable;

end Aion.Awaitable;
