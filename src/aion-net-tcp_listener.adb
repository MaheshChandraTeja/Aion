with Ada.Exceptions;
with Aion.Errors;
with Aion.Reactor;
with Aion.Readiness;
with Aion.Waker;

package body Aion.Net.TCP_Listener is
   use type Aion.IO_Resource.Native_Handle;
   use type Aion.Reactor.Reactor_Service_Access;
   use type GNAT.Sockets.Socket_Type;

   Max_Pending_Accepts : constant Positive := 4_096;

   protected Native_Ids is
      procedure Next (Handle : out Aion.IO_Resource.Native_Handle);
   private
      Value : Aion.IO_Resource.Native_Handle := 200_000;
   end Native_Ids;

   protected body Native_Ids is
      procedure Next (Handle : out Aion.IO_Resource.Native_Handle) is
      begin
         Handle := Value;
         Value := Value + 1;
      end Next;
   end Native_Ids;

   type Accept_Context is record
      Used     : Boolean := False;
      Listener : TCP_Listener := Null_Listener;
      Reactor  : Aion.Reactor.Reactor_Service_Access := null;
      Future   : Aion.Net.TCP_Stream.Stream_Futures.Future_Handle :=
        Aion.Net.TCP_Stream.Stream_Futures.Null_Future;
      Name     : US.Unbounded_String := US.Null_Unbounded_String;
   end record;

   type Accept_Context_Array is array (Positive range <>) of Accept_Context;

   protected Accept_Registry is
      procedure Put (Context : Accept_Context; Accepted : out Boolean);
      procedure Take (Context : out Accept_Context; Found : out Boolean);
   private
      Items : Accept_Context_Array (1 .. Max_Pending_Accepts);
   end Accept_Registry;

   protected body Accept_Registry is
      procedure Put (Context : Accept_Context; Accepted : out Boolean) is
      begin
         Accepted := False;
         for I in Items'Range loop
            if not Items (I).Used then
               Items (I) := Context;
               Items (I).Used := True;
               Accepted := True;
               return;
            end if;
         end loop;
      end Put;

      procedure Take (Context : out Accept_Context; Found : out Boolean) is
      begin
         Found := False;
         Context := (others => <>);
         for I in Items'Range loop
            if Items (I).Used then
               Context := Items (I);
               Items (I).Used := False;
               Found := True;
               return;
            end if;
         end loop;
      end Take;
   end Accept_Registry;

   function Register_Listener
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Name    : String) return Aion.Reactor.Register_Results.Result_Type is
      Handle : Aion.IO_Resource.Native_Handle;
   begin
      Native_Ids.Next (Handle);
      return Aion.Reactor.Register
        (Service  => Aion.Runtime.Reactor_Of (Runtime),
         Handle   => Handle,
         Interest => Aion.Readiness.Readable,
         Waker    => Aion.Waker.Noop,
         Name     => Name);
   end Register_Listener;

   procedure Run_Accept is
      Context : Accept_Context;
      Found   : Boolean;
      Socket  : GNAT.Sockets.Socket_Type := GNAT.Sockets.No_Socket;
      Peer    : GNAT.Sockets.Sock_Addr_Type;
      Stream  : Aion.Net.TCP_Stream.Stream_Results.Result_Type;
      Ignored : Aion.Net.TCP_Stream.Stream_Futures.Operation_Results.Result_Type;
      Signal  : Aion.Reactor.Operation_Results.Result_Type;
      pragma Unreferenced (Ignored, Signal);
   begin
      Accept_Registry.Take (Context, Found);
      if not Found then
         return;
      end if;

      if not Context.Listener.Open then
         Ignored := Aion.Net.TCP_Stream.Stream_Futures.Complete_Failure
           (Context.Future, Aion.Errors.Resource_Closed, "listener is closed", "Aion.Net.TCP_Listener.Async_Accept");
         return;
      end if;

      begin
         GNAT.Sockets.Accept_Socket (Context.Listener.Socket, Socket, Peer);

         if Context.Reactor /= null then
            Signal := Aion.Reactor.Notify_Readiness
              (Context.Reactor, Context.Listener.Resource, Aion.Readiness.Readable);
         end if;

         Stream := Aion.Net.TCP_Stream.From_Accepted_Socket
           (Context.Reactor,
            Socket,
            Aion.Net.Address.From_Sock_Addr (Peer),
            US.To_String (Context.Name));

         if Aion.Net.TCP_Stream.Stream_Results.Is_Ok (Stream) then
            Ignored := Aion.Net.TCP_Stream.Stream_Futures.Complete_Success
              (Context.Future, Aion.Net.TCP_Stream.Stream_Results.Value (Stream));
         else
            Ignored := Aion.Net.TCP_Stream.Stream_Futures.Complete_Failure
              (Context.Future, Aion.Net.TCP_Stream.Stream_Results.Error (Stream));
         end if;
      exception
         when E : others =>
            begin
               if Socket /= GNAT.Sockets.No_Socket then
                  GNAT.Sockets.Close_Socket (Socket);
               end if;
            exception
               when others => null;
            end;
            Ignored := Aion.Net.TCP_Stream.Stream_Futures.Complete_Failure
              (Context.Future, Aion.Errors.Io_Error,
               "accept failed: " & Ada.Exceptions.Exception_Message (E),
               "Aion.Net.TCP_Listener.Async_Accept");
      end;
   end Run_Accept;

   function Bind
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Address : Aion.Net.Address.Network_Address;
      Options : Aion.Net.Socket_Options.Socket_Options :=
        Aion.Net.Socket_Options.Default_TCP;
      Backlog : Positive := 128;
      Name    : String := "tcp-listener") return Listener_Results.Result_Type is
      Socket  : GNAT.Sockets.Socket_Type := GNAT.Sockets.No_Socket;
      Reg     : Aion.Reactor.Register_Results.Result_Type;
      Applied : Aion.Net.Operation_Results.Result_Type;
      pragma Unreferenced (Applied);
   begin
      Aion.Net.Initialize;

      if not Aion.Runtime.Is_Running (Runtime) then
         return Listener_Results.Failure
           (Aion.Errors.Invalid_State, "runtime is not running", "Aion.Net.TCP_Listener.Bind");
      end if;

      GNAT.Sockets.Create_Socket (Socket, GNAT.Sockets.Family_Inet, GNAT.Sockets.Socket_Stream);
      Applied := Aion.Net.Socket_Options.Apply_TCP (Socket, Options);
      GNAT.Sockets.Bind_Socket (Socket, Aion.Net.Address.To_Sock_Addr (Address));
      GNAT.Sockets.Listen_Socket (Socket, Backlog);

      Reg := Register_Listener (Runtime, Name);
      if Aion.Reactor.Register_Results.Is_Err (Reg) then
         GNAT.Sockets.Close_Socket (Socket);
         return Listener_Results.Failure (Aion.Reactor.Register_Results.Error (Reg));
      end if;

      return Listener_Results.Success
        ((Socket   => Socket,
          Local    => Address,
          Resource => Aion.Reactor.Register_Results.Value (Reg),
          Open     => True,
          Name     => US.To_Unbounded_String (Name)));
   exception
      when E : others =>
         begin
            if Socket /= GNAT.Sockets.No_Socket then
               GNAT.Sockets.Close_Socket (Socket);
            end if;
         exception
            when others => null;
         end;
         return Listener_Results.Failure
           (Aion.Errors.Io_Error,
            "bind failed: " & Ada.Exceptions.Exception_Message (E),
            "Aion.Net.TCP_Listener.Bind");
   end Bind;

   function Async_Accept
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Listener : TCP_Listener;
      Timeout  : Aion.Types.Milliseconds := 0;
      Name     : String := "tcp-accept")
      return Aion.Net.TCP_Stream.Stream_Futures.Future_Handle is
      pragma Unreferenced (Timeout);
      Future  : constant Aion.Net.TCP_Stream.Stream_Futures.Future_Handle :=
        Aion.Net.TCP_Stream.Stream_Futures.Create (Name);
      Context : Accept_Context;
      Put_Ok  : Boolean;
      Spawned : Aion.Runtime.Spawn_Results.Result_Type;
      Ignored : Aion.Net.TCP_Stream.Stream_Futures.Operation_Results.Result_Type;
      pragma Unreferenced (Ignored);
   begin
      Context :=
        (Used     => True,
         Listener => Listener,
         Reactor  => Aion.Runtime.Reactor_Of (Runtime),
         Future   => Future,
         Name     => US.To_Unbounded_String (Name));

      Accept_Registry.Put (Context, Put_Ok);
      if not Put_Ok then
         Ignored := Aion.Net.TCP_Stream.Stream_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "accept registry is full", "Aion.Net.TCP_Listener.Async_Accept");
         return Future;
      end if;

      Spawned := Aion.Runtime.Spawn (Runtime, Name, Run_Accept'Access);
      if Aion.Runtime.Spawn_Results.Is_Err (Spawned) then
         Ignored := Aion.Net.TCP_Stream.Stream_Futures.Complete_Failure
           (Future, Aion.Runtime.Spawn_Results.Error (Spawned));
      end if;
      return Future;
   end Async_Accept;

   function Close
     (Runtime  : in out Aion.Runtime.Runtime_Handle;
      Listener : in out TCP_Listener) return Aion.Net.Operation_Results.Result_Type is
      Unreg : Aion.Reactor.Operation_Results.Result_Type;
      pragma Unreferenced (Unreg);
   begin
      if not Listener.Open then
         return Aion.Net.Operation_Results.Success (True);
      end if;

      begin
         Unreg := Aion.Reactor.Unregister
           (Aion.Runtime.Reactor_Of (Runtime), Listener.Resource);
      exception
         when others => null;
      end;

      GNAT.Sockets.Close_Socket (Listener.Socket);
      Listener.Open := False;
      return Aion.Net.Operation_Results.Success (True);
   exception
      when E : others =>
         Listener.Open := False;
         return Aion.Net.Operation_Results.Failure
           (Aion.Errors.Io_Error,
            "listener close failed: " & Ada.Exceptions.Exception_Message (E),
            "Aion.Net.TCP_Listener.Close");
   end Close;

   function Is_Open (Listener : TCP_Listener) return Boolean is
   begin
      return Listener.Open;
   end Is_Open;

   function Local_Address_Of
     (Listener : TCP_Listener) return Aion.Net.Address.Network_Address is
   begin
      return Listener.Local;
   end Local_Address_Of;

   function Resource_Of (Listener : TCP_Listener) return Aion.IO_Resource.IO_Resource is
   begin
      return Listener.Resource;
   end Resource_Of;

   function Image (Listener : TCP_Listener) return String is
   begin
      return "TCP_Listener(name=" & US.To_String (Listener.Name) &
        ", open=" & Boolean'Image (Listener.Open) &
        ", local=" & Aion.Net.Address.Image (Listener.Local) & ")";
   end Image;

end Aion.Net.TCP_Listener;
