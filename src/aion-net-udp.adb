with Ada.Exceptions;
with Ada.Streams;
with Aion.Errors;
with Aion.Reactor;
with Aion.Readiness;
with Aion.Waker;

package body Aion.Net.UDP is
   use type Ada.Streams.Stream_Element_Offset;
   use type Aion.IO_Resource.Native_Handle;
   use type Aion.Reactor.Reactor_Service_Access;
   use type GNAT.Sockets.Socket_Type;

   Max_Pending_Ops : constant Positive := 4_096;

   protected Native_Ids is
      procedure Next (Handle : out Aion.IO_Resource.Native_Handle);
   private
      Value : Aion.IO_Resource.Native_Handle := 500_000;
   end Native_Ids;

   protected body Native_Ids is
      procedure Next (Handle : out Aion.IO_Resource.Native_Handle) is
      begin
         Handle := Value;
         Value := Value + 1;
      end Next;
   end Native_Ids;

   type Send_Context is record
      Used    : Boolean := False;
      Socket  : UDP_Socket := Null_Socket;
      Peer    : Aion.Net.Address.Network_Address := Aion.Net.Address.Localhost (0);
      Payload : Aion.Net.Net_Buffer := Aion.Net.Empty_Buffer;
      Reactor : Aion.Reactor.Reactor_Service_Access := null;
      Future  : Aion.Net.Count_Futures.Future_Handle := Aion.Net.Count_Futures.Null_Future;
   end record;

   type Receive_Context is record
      Used      : Boolean := False;
      Socket    : UDP_Socket := Null_Socket;
      Max_Bytes : Aion.Net.Buffer_Length := Aion.Net.Max_Buffer_Size;
      Reactor   : Aion.Reactor.Reactor_Service_Access := null;
      Future    : Datagram_Futures.Future_Handle := Datagram_Futures.Null_Future;
   end record;

   type Send_Context_Array is array (Positive range <>) of Send_Context;
   type Receive_Context_Array is array (Positive range <>) of Receive_Context;

   protected Send_Registry is
      procedure Put (Context : Send_Context; Accepted : out Boolean);
      procedure Take (Context : out Send_Context; Found : out Boolean);
   private
      Items : Send_Context_Array (1 .. Max_Pending_Ops);
   end Send_Registry;

   protected Receive_Registry is
      procedure Put (Context : Receive_Context; Accepted : out Boolean);
      procedure Take (Context : out Receive_Context; Found : out Boolean);
   private
      Items : Receive_Context_Array (1 .. Max_Pending_Ops);
   end Receive_Registry;

   protected body Send_Registry is
      procedure Put (Context : Send_Context; Accepted : out Boolean) is
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

      procedure Take (Context : out Send_Context; Found : out Boolean) is
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
   end Send_Registry;

   protected body Receive_Registry is
      procedure Put (Context : Receive_Context; Accepted : out Boolean) is
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

      procedure Take (Context : out Receive_Context; Found : out Boolean) is
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
   end Receive_Registry;

   function Register_UDP
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Name    : String) return Aion.Reactor.Register_Results.Result_Type is
      Handle : Aion.IO_Resource.Native_Handle;
   begin
      Native_Ids.Next (Handle);
      return Aion.Reactor.Register
        (Service  => Aion.Runtime.Reactor_Of (Runtime),
         Handle   => Handle,
         Interest => Aion.Readiness.Read_Write,
         Waker    => Aion.Waker.Noop,
         Name     => Name);
   end Register_UDP;

   procedure Run_Send is
      Context : Send_Context;
      Found   : Boolean;
      Data    : Ada.Streams.Stream_Element_Array (1 .. Ada.Streams.Stream_Element_Offset (Aion.Net.Max_Buffer_Size));
      Last_In : Ada.Streams.Stream_Element_Offset;
      Last_Out : Ada.Streams.Stream_Element_Offset;
      Sent    : Natural := 0;
      Future_Result : Aion.Net.Count_Futures.Operation_Results.Result_Type;
      Signal  : Aion.Reactor.Operation_Results.Result_Type;
      pragma Unreferenced (Future_Result, Signal);
   begin
      Send_Registry.Take (Context, Found);
      if not Found then
         return;
      end if;

      if not Context.Socket.Open then
         Future_Result := Aion.Net.Count_Futures.Complete_Failure
           (Context.Future, Aion.Errors.Resource_Closed, "udp socket is closed", "Aion.Net.UDP.Async_Send_To");
         return;
      end if;

      begin
         Aion.Net.To_Stream (Context.Payload, Data, Last_In);
         if Last_In >= Data'First then
            GNAT.Sockets.Send_Socket
              (Context.Socket.Socket,
               Data (Data'First .. Last_In),
               Last_Out,
               Aion.Net.Address.To_Sock_Addr (Context.Peer));
            Sent := Natural (Last_Out - Data'First + 1);
         end if;

         if Context.Reactor /= null then
            Signal := Aion.Reactor.Notify_Readiness
              (Context.Reactor, Context.Socket.Resource, Aion.Readiness.Writable);
         end if;

         Future_Result := Aion.Net.Count_Futures.Complete_Success (Context.Future, Sent);
      exception
         when E : others =>
            Future_Result := Aion.Net.Count_Futures.Complete_Failure
              (Context.Future, Aion.Errors.Io_Error,
               "udp send failed: " & Ada.Exceptions.Exception_Message (E),
               "Aion.Net.UDP.Async_Send_To");
      end;
   end Run_Send;

   procedure Run_Receive is
      Context : Receive_Context;
      Found   : Boolean;
      Data    : Ada.Streams.Stream_Element_Array (1 .. Ada.Streams.Stream_Element_Offset (Aion.Net.Max_Buffer_Size));
      Last    : Ada.Streams.Stream_Element_Offset;
      Peer    : GNAT.Sockets.Sock_Addr_Type;
      Count   : Natural := 0;
      Future_Result : Datagram_Futures.Operation_Results.Result_Type;
      Signal  : Aion.Reactor.Operation_Results.Result_Type;
      pragma Unreferenced (Future_Result, Signal);
   begin
      Receive_Registry.Take (Context, Found);
      if not Found then
         return;
      end if;

      if not Context.Socket.Open then
         Future_Result := Datagram_Futures.Complete_Failure
           (Context.Future, Aion.Errors.Resource_Closed, "udp socket is closed", "Aion.Net.UDP.Async_Receive_From");
         return;
      end if;

      begin
         GNAT.Sockets.Receive_Socket (Context.Socket.Socket, Data, Last, Peer);
         if Last >= Data'First then
            Count := Natural'Min
              (Natural (Last - Data'First + 1), Natural (Context.Max_Bytes));
         end if;

         if Context.Reactor /= null then
            Signal := Aion.Reactor.Notify_Readiness
              (Context.Reactor, Context.Socket.Resource, Aion.Readiness.Readable);
         end if;

         if Count = 0 then
            Future_Result := Datagram_Futures.Complete_Success
              (Context.Future,
               (Payload => Aion.Net.Empty_Buffer,
                Peer    => Aion.Net.Address.From_Sock_Addr (Peer)));
         else
            Future_Result := Datagram_Futures.Complete_Success
              (Context.Future,
               (Payload => Aion.Net.From_Stream
                  (Data (Data'First .. Data'First + Ada.Streams.Stream_Element_Offset (Count) - 1)),
                Peer    => Aion.Net.Address.From_Sock_Addr (Peer)));
         end if;
      exception
         when E : others =>
            Future_Result := Datagram_Futures.Complete_Failure
              (Context.Future, Aion.Errors.Io_Error,
               "udp receive failed: " & Ada.Exceptions.Exception_Message (E),
               "Aion.Net.UDP.Async_Receive_From");
      end;
   end Run_Receive;

   function Bind
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Address : Aion.Net.Address.Network_Address;
      Options : Aion.Net.Socket_Options.Socket_Options :=
        Aion.Net.Socket_Options.Default_UDP;
      Name    : String := "udp-socket") return Socket_Results.Result_Type is
      Socket  : GNAT.Sockets.Socket_Type := GNAT.Sockets.No_Socket;
      Applied : Aion.Net.Operation_Results.Result_Type;
      Reg     : Aion.Reactor.Register_Results.Result_Type;
      pragma Unreferenced (Applied);
   begin
      Aion.Net.Initialize;

      if not Aion.Runtime.Is_Running (Runtime) then
         return Socket_Results.Failure
           (Aion.Errors.Invalid_State, "runtime is not running", "Aion.Net.UDP.Bind");
      end if;

      GNAT.Sockets.Create_Socket (Socket, GNAT.Sockets.Family_Inet, GNAT.Sockets.Socket_Datagram);
      Applied := Aion.Net.Socket_Options.Apply_UDP (Socket, Options);
      GNAT.Sockets.Bind_Socket (Socket, Aion.Net.Address.To_Sock_Addr (Address));

      Reg := Register_UDP (Runtime, Name);
      if Aion.Reactor.Register_Results.Is_Err (Reg) then
         GNAT.Sockets.Close_Socket (Socket);
         return Socket_Results.Failure (Aion.Reactor.Register_Results.Error (Reg));
      end if;

      return Socket_Results.Success
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
         return Socket_Results.Failure
           (Aion.Errors.Io_Error,
            "udp bind failed: " & Ada.Exceptions.Exception_Message (E),
            "Aion.Net.UDP.Bind");
   end Bind;

   function Async_Send_To
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Socket  : UDP_Socket;
      Peer    : Aion.Net.Address.Network_Address;
      Payload : Aion.Net.Net_Buffer;
      Timeout : Aion.Types.Milliseconds := 0;
      Name    : String := "udp-send") return Aion.Net.Count_Futures.Future_Handle is
      pragma Unreferenced (Timeout);
      Future  : constant Aion.Net.Count_Futures.Future_Handle := Aion.Net.Count_Futures.Create (Name);
      Context : Send_Context;
      Put_Ok  : Boolean;
      Spawned : Aion.Runtime.Spawn_Results.Result_Type;
      Ignored : Aion.Net.Count_Futures.Operation_Results.Result_Type;
   begin
      Context :=
        (Used    => True,
         Socket  => Socket,
         Peer    => Peer,
         Payload => Payload,
         Reactor => Aion.Runtime.Reactor_Of (Runtime),
         Future  => Future);
      Send_Registry.Put (Context, Put_Ok);
      if not Put_Ok then
         Ignored := Aion.Net.Count_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "udp send registry is full", "Aion.Net.UDP.Async_Send_To");
         return Future;
      end if;

      Spawned := Aion.Runtime.Spawn (Runtime, Name, Run_Send'Access);
      if Aion.Runtime.Spawn_Results.Is_Err (Spawned) then
         Ignored := Aion.Net.Count_Futures.Complete_Failure
           (Future, Aion.Runtime.Spawn_Results.Error (Spawned));
      end if;
      return Future;
   end Async_Send_To;

   function Async_Receive_From
     (Runtime   : in out Aion.Runtime.Runtime_Handle;
      Socket    : UDP_Socket;
      Max_Bytes : Aion.Net.Buffer_Length := Aion.Net.Max_Buffer_Size;
      Timeout   : Aion.Types.Milliseconds := 0;
      Name      : String := "udp-receive") return Datagram_Futures.Future_Handle is
      pragma Unreferenced (Timeout);
      Future  : constant Datagram_Futures.Future_Handle := Datagram_Futures.Create (Name);
      Context : Receive_Context;
      Put_Ok  : Boolean;
      Spawned : Aion.Runtime.Spawn_Results.Result_Type;
      Ignored : Datagram_Futures.Operation_Results.Result_Type;
   begin
      Context :=
        (Used      => True,
         Socket    => Socket,
         Max_Bytes => Max_Bytes,
         Reactor   => Aion.Runtime.Reactor_Of (Runtime),
         Future    => Future);
      Receive_Registry.Put (Context, Put_Ok);
      if not Put_Ok then
         Ignored := Datagram_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "udp receive registry is full", "Aion.Net.UDP.Async_Receive_From");
         return Future;
      end if;

      Spawned := Aion.Runtime.Spawn (Runtime, Name, Run_Receive'Access);
      if Aion.Runtime.Spawn_Results.Is_Err (Spawned) then
         Ignored := Datagram_Futures.Complete_Failure
           (Future, Aion.Runtime.Spawn_Results.Error (Spawned));
      end if;
      return Future;
   end Async_Receive_From;

   function Close
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Socket  : in out UDP_Socket) return Aion.Net.Operation_Results.Result_Type is
      Unreg : Aion.Reactor.Operation_Results.Result_Type;
      pragma Unreferenced (Unreg);
   begin
      if not Socket.Open then
         return Aion.Net.Operation_Results.Success (True);
      end if;

      begin
         Unreg := Aion.Reactor.Unregister
           (Aion.Runtime.Reactor_Of (Runtime), Socket.Resource);
      exception
         when others => null;
      end;

      GNAT.Sockets.Close_Socket (Socket.Socket);
      Socket.Open := False;
      return Aion.Net.Operation_Results.Success (True);
   exception
      when E : others =>
         Socket.Open := False;
         return Aion.Net.Operation_Results.Failure
           (Aion.Errors.Io_Error,
            "udp close failed: " & Ada.Exceptions.Exception_Message (E),
            "Aion.Net.UDP.Close");
   end Close;

   function Is_Open (Socket : UDP_Socket) return Boolean is
   begin
      return Socket.Open;
   end Is_Open;

   function Local_Address_Of
     (Socket : UDP_Socket) return Aion.Net.Address.Network_Address is
   begin
      return Socket.Local;
   end Local_Address_Of;

   function Resource_Of (Socket : UDP_Socket) return Aion.IO_Resource.IO_Resource is
   begin
      return Socket.Resource;
   end Resource_Of;

   function Image (Socket : UDP_Socket) return String is
   begin
      return "UDP_Socket(name=" & US.To_String (Socket.Name) &
        ", open=" & Boolean'Image (Socket.Open) &
        ", local=" & Aion.Net.Address.Image (Socket.Local) & ")";
   end Image;

   function Image (Item : Datagram) return String is
   begin
      return "Datagram(peer=" & Aion.Net.Address.Image (Item.Peer) &
        ", payload=" & Aion.Net.Image (Item.Payload) & ")";
   end Image;

end Aion.Net.UDP;
