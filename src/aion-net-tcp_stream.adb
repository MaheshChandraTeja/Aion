with Ada.Exceptions;
with Ada.Streams;
with Aion.Errors;
with Aion.Readiness;
with Aion.Waker;

package body Aion.Net.TCP_Stream is
   use type Ada.Streams.Stream_Element_Offset;
   use type Aion.IO_Resource.Native_Handle;
   use type Aion.Reactor.Reactor_Service_Access;
   use type GNAT.Sockets.Socket_Type;

   Max_Pending_Ops : constant Positive := 4_096;

   protected Native_Ids is
      procedure Next (Handle : out Aion.IO_Resource.Native_Handle);
   private
      Value : Aion.IO_Resource.Native_Handle := 10_000;
   end Native_Ids;

   protected body Native_Ids is
      procedure Next (Handle : out Aion.IO_Resource.Native_Handle) is
      begin
         Handle := Value;
         Value := Value + 1;
      end Next;
   end Native_Ids;

   function Register_Stream
     (Reactor : not null Aion.Reactor.Reactor_Service_Access;
      Name    : String) return Aion.Reactor.Register_Results.Result_Type is
      Handle : Aion.IO_Resource.Native_Handle;
   begin
      Native_Ids.Next (Handle);
      return Aion.Reactor.Register
        (Service  => Reactor,
         Handle   => Handle,
         Interest => Aion.Readiness.Read_Write,
         Waker    => Aion.Waker.Noop,
         Name     => Name);
   end Register_Stream;

   function Register_Stream
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Name    : String) return Aion.Reactor.Register_Results.Result_Type is
   begin
      return Register_Stream (Aion.Runtime.Reactor_Of (Runtime), Name);
   end Register_Stream;

   type Connect_Context is record
      Used     : Boolean := False;
      Socket   : GNAT.Sockets.Socket_Type := GNAT.Sockets.No_Socket;
      Address  : Aion.Net.Address.Network_Address := Aion.Net.Address.Localhost (0);
      Resource : Aion.IO_Resource.IO_Resource := Aion.IO_Resource.Null_Resource;
      Reactor  : Aion.Reactor.Reactor_Service_Access := null;
      Future   : Stream_Futures.Future_Handle := Stream_Futures.Null_Future;
      Name     : US.Unbounded_String := US.Null_Unbounded_String;
   end record;

   type Read_Context is record
      Used      : Boolean := False;
      Stream    : TCP_Stream := Null_Stream;
      Max_Bytes : Aion.Net.Buffer_Length := Aion.Net.Max_Buffer_Size;
      Reactor   : Aion.Reactor.Reactor_Service_Access := null;
      Future    : Aion.Net.Buffer_Futures.Future_Handle := Aion.Net.Buffer_Futures.Null_Future;
   end record;

   type Write_Context is record
      Used    : Boolean := False;
      Stream  : TCP_Stream := Null_Stream;
      Buffer  : Aion.Net.Net_Buffer := Aion.Net.Empty_Buffer;
      Reactor : Aion.Reactor.Reactor_Service_Access := null;
      Future  : Aion.Net.Count_Futures.Future_Handle := Aion.Net.Count_Futures.Null_Future;
   end record;

   type Connect_Context_Array is array (Positive range <>) of Connect_Context;
   type Read_Context_Array is array (Positive range <>) of Read_Context;
   type Write_Context_Array is array (Positive range <>) of Write_Context;

   protected Connect_Registry is
      procedure Put (Context : Connect_Context; Accepted : out Boolean);
      procedure Take (Context : out Connect_Context; Found : out Boolean);
   private
      Items : Connect_Context_Array (1 .. Max_Pending_Ops);
   end Connect_Registry;

   protected Read_Registry is
      procedure Put (Context : Read_Context; Accepted : out Boolean);
      procedure Take (Context : out Read_Context; Found : out Boolean);
   private
      Items : Read_Context_Array (1 .. Max_Pending_Ops);
   end Read_Registry;

   protected Write_Registry is
      procedure Put (Context : Write_Context; Accepted : out Boolean);
      procedure Take (Context : out Write_Context; Found : out Boolean);
   private
      Items : Write_Context_Array (1 .. Max_Pending_Ops);
   end Write_Registry;

   protected body Connect_Registry is
      procedure Put (Context : Connect_Context; Accepted : out Boolean) is
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

      procedure Take (Context : out Connect_Context; Found : out Boolean) is
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
   end Connect_Registry;

   protected body Read_Registry is
      procedure Put (Context : Read_Context; Accepted : out Boolean) is
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

      procedure Take (Context : out Read_Context; Found : out Boolean) is
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
   end Read_Registry;

   protected body Write_Registry is
      procedure Put (Context : Write_Context; Accepted : out Boolean) is
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

      procedure Take (Context : out Write_Context; Found : out Boolean) is
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
   end Write_Registry;

   procedure Run_Connect;
   procedure Run_Read;
   procedure Run_Write;

   procedure Run_Connect is
      Context : Connect_Context;
      Found   : Boolean;
      Done    : Stream_Futures.Operation_Results.Result_Type;
      Signal  : Aion.Reactor.Operation_Results.Result_Type;
      pragma Unreferenced (Done, Signal);
   begin
      Connect_Registry.Take (Context, Found);
      if not Found then
         return;
      end if;

      begin
         GNAT.Sockets.Connect_Socket
           (Context.Socket,
            Aion.Net.Address.To_Sock_Addr (Context.Address));

         if Context.Reactor /= null then
            Signal := Aion.Reactor.Notify_Readiness
              (Context.Reactor, Context.Resource, Aion.Readiness.Writable);
         end if;

         Done := Stream_Futures.Complete_Success
           (Context.Future,
            (Socket   => Context.Socket,
             Peer     => Context.Address,
             Resource => Context.Resource,
             Open     => True,
             Name     => Context.Name));
      exception
         when E : others =>
            begin
               GNAT.Sockets.Close_Socket (Context.Socket);
            exception
               when others => null;
            end;
            Done := Stream_Futures.Complete_Failure
              (Context.Future, Aion.Errors.Io_Error,
               "connect failed: " & Ada.Exceptions.Exception_Message (E),
               "Aion.Net.TCP_Stream.Run_Connect");
      end;
   end Run_Connect;

   procedure Run_Read is
      Context : Read_Context;
      Found   : Boolean;
      Data    : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Aion.Net.Max_Buffer_Size));
      Last    : Ada.Streams.Stream_Element_Offset;
      Count   : Natural := 0;
      Done    : Aion.Net.Buffer_Futures.Operation_Results.Result_Type;
      Signal  : Aion.Reactor.Operation_Results.Result_Type;
      pragma Unreferenced (Done, Signal);
   begin
      Read_Registry.Take (Context, Found);
      if not Found then
         return;
      end if;

      if not Context.Stream.Open then
         Done := Aion.Net.Buffer_Futures.Complete_Failure
           (Context.Future, Aion.Errors.Resource_Closed,
            "stream is closed", "Aion.Net.TCP_Stream.Run_Read");
         return;
      end if;

      begin
         GNAT.Sockets.Receive_Socket (Context.Stream.Socket, Data, Last);
         if Last >= Data'First then
            Count := Natural'Min
              (Natural (Last - Data'First + 1), Natural (Context.Max_Bytes));
         end if;

         if Context.Reactor /= null then
            Signal := Aion.Reactor.Notify_Readiness
              (Context.Reactor, Context.Stream.Resource, Aion.Readiness.Readable);
         end if;

         if Count = 0 then
            Done := Aion.Net.Buffer_Futures.Complete_Success
              (Context.Future, Aion.Net.Empty_Buffer);
         else
            Done := Aion.Net.Buffer_Futures.Complete_Success
              (Context.Future,
               Aion.Net.From_Stream
                 (Data (Data'First .. Data'First + Ada.Streams.Stream_Element_Offset (Count) - 1)));
         end if;
      exception
         when E : others =>
            Done := Aion.Net.Buffer_Futures.Complete_Failure
              (Context.Future, Aion.Errors.Io_Error,
               "read failed: " & Ada.Exceptions.Exception_Message (E),
               "Aion.Net.TCP_Stream.Run_Read");
      end;
   end Run_Read;

   procedure Run_Write is
      Context  : Write_Context;
      Found    : Boolean;
      Data     : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Aion.Net.Max_Buffer_Size));
      Last_In  : Ada.Streams.Stream_Element_Offset;
      Last_Out : Ada.Streams.Stream_Element_Offset;
      Sent     : Natural := 0;
      Done     : Aion.Net.Count_Futures.Operation_Results.Result_Type;
      Signal   : Aion.Reactor.Operation_Results.Result_Type;
      pragma Unreferenced (Done, Signal);
   begin
      Write_Registry.Take (Context, Found);
      if not Found then
         return;
      end if;

      if not Context.Stream.Open then
         Done := Aion.Net.Count_Futures.Complete_Failure
           (Context.Future, Aion.Errors.Resource_Closed,
            "stream is closed", "Aion.Net.TCP_Stream.Run_Write");
         return;
      end if;

      begin
         Aion.Net.To_Stream (Context.Buffer, Data, Last_In);
         if Last_In >= Data'First then
            GNAT.Sockets.Send_Socket
              (Context.Stream.Socket, Data (Data'First .. Last_In), Last_Out);
            Sent := Natural (Last_Out - Data'First + 1);
         end if;

         if Context.Reactor /= null then
            Signal := Aion.Reactor.Notify_Readiness
              (Context.Reactor, Context.Stream.Resource, Aion.Readiness.Writable);
         end if;

         Done := Aion.Net.Count_Futures.Complete_Success (Context.Future, Sent);
      exception
         when E : others =>
            Done := Aion.Net.Count_Futures.Complete_Failure
              (Context.Future, Aion.Errors.Io_Error,
               "write failed: " & Ada.Exceptions.Exception_Message (E),
               "Aion.Net.TCP_Stream.Run_Write");
      end;
   end Run_Write;

   function Async_Connect
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Address : Aion.Net.Address.Network_Address;
      Options : Aion.Net.Socket_Options.Socket_Options :=
        Aion.Net.Socket_Options.Default_TCP;
      Name    : String := "tcp-connect") return Stream_Futures.Future_Handle is
      Future  : constant Stream_Futures.Future_Handle := Stream_Futures.Create (Name);
      Socket  : GNAT.Sockets.Socket_Type := GNAT.Sockets.No_Socket;
      Reg     : Aion.Reactor.Register_Results.Result_Type;
      Applied : Aion.Net.Operation_Results.Result_Type;
      Context : Connect_Context;
      Put_Ok  : Boolean;
      Spawned : Aion.Runtime.Spawn_Results.Result_Type;
      Done    : Stream_Futures.Operation_Results.Result_Type;
      pragma Unreferenced (Applied, Done);
   begin
      Aion.Net.Initialize;

      if not Aion.Runtime.Is_Running (Runtime) then
         Done := Stream_Futures.Complete_Failure
           (Future, Aion.Errors.Invalid_State,
            "runtime is not running", "Aion.Net.TCP_Stream.Async_Connect");
         return Future;
      end if;

      begin
         GNAT.Sockets.Create_Socket
           (Socket, GNAT.Sockets.Family_Inet, GNAT.Sockets.Socket_Stream);
         Applied := Aion.Net.Socket_Options.Apply_TCP (Socket, Options);
         Reg := Register_Stream (Runtime, Name);

         if Aion.Reactor.Register_Results.Is_Err (Reg) then
            GNAT.Sockets.Close_Socket (Socket);
            Done := Stream_Futures.Complete_Failure
              (Future, Aion.Reactor.Register_Results.Error (Reg));
            return Future;
         end if;

         Context :=
           (Used     => True,
            Socket   => Socket,
            Address  => Address,
            Resource => Aion.Reactor.Register_Results.Value (Reg),
            Reactor  => Aion.Runtime.Reactor_Of (Runtime),
            Future   => Future,
            Name     => US.To_Unbounded_String (Name));

         Connect_Registry.Put (Context, Put_Ok);
         if not Put_Ok then
            GNAT.Sockets.Close_Socket (Socket);
            Done := Stream_Futures.Complete_Failure
              (Future, Aion.Errors.Capacity_Exceeded,
               "connect registry is full", "Aion.Net.TCP_Stream.Async_Connect");
            return Future;
         end if;

         Spawned := Aion.Runtime.Spawn (Runtime, Name, Run_Connect'Access);
         if Aion.Runtime.Spawn_Results.Is_Err (Spawned) then
            Done := Stream_Futures.Complete_Failure
              (Future, Aion.Runtime.Spawn_Results.Error (Spawned));
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
            Done := Stream_Futures.Complete_Failure
              (Future, Aion.Errors.Io_Error,
               "connect setup failed: " & Ada.Exceptions.Exception_Message (E),
               "Aion.Net.TCP_Stream.Async_Connect");
      end;

      return Future;
   end Async_Connect;

   function Async_Read
     (Runtime   : in out Aion.Runtime.Runtime_Handle;
      Stream    : TCP_Stream;
      Max_Bytes : Aion.Net.Buffer_Length := Aion.Net.Max_Buffer_Size;
      Timeout   : Aion.Types.Milliseconds := 0;
      Name      : String := "tcp-read") return Aion.Net.Buffer_Futures.Future_Handle is
      pragma Unreferenced (Timeout);
      Future  : constant Aion.Net.Buffer_Futures.Future_Handle := Aion.Net.Buffer_Futures.Create (Name);
      Context : Read_Context;
      Put_Ok  : Boolean;
      Spawned : Aion.Runtime.Spawn_Results.Result_Type;
      Done    : Aion.Net.Buffer_Futures.Operation_Results.Result_Type;
      pragma Unreferenced (Done);
   begin
      Context :=
        (Used      => True,
         Stream    => Stream,
         Max_Bytes => Max_Bytes,
         Reactor   => Aion.Runtime.Reactor_Of (Runtime),
         Future    => Future);
      Read_Registry.Put (Context, Put_Ok);

      if not Put_Ok then
         Done := Aion.Net.Buffer_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "read registry is full", "Aion.Net.TCP_Stream.Async_Read");
         return Future;
      end if;

      Spawned := Aion.Runtime.Spawn (Runtime, Name, Run_Read'Access);
      if Aion.Runtime.Spawn_Results.Is_Err (Spawned) then
         Done := Aion.Net.Buffer_Futures.Complete_Failure
           (Future, Aion.Runtime.Spawn_Results.Error (Spawned));
      end if;
      return Future;
   end Async_Read;

   function Async_Write
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Stream  : TCP_Stream;
      Buffer  : Aion.Net.Net_Buffer;
      Timeout : Aion.Types.Milliseconds := 0;
      Name    : String := "tcp-write") return Aion.Net.Count_Futures.Future_Handle is
      pragma Unreferenced (Timeout);
      Future  : constant Aion.Net.Count_Futures.Future_Handle := Aion.Net.Count_Futures.Create (Name);
      Context : Write_Context;
      Put_Ok  : Boolean;
      Spawned : Aion.Runtime.Spawn_Results.Result_Type;
      Done    : Aion.Net.Count_Futures.Operation_Results.Result_Type;
      pragma Unreferenced (Done);
   begin
      Context :=
        (Used    => True,
         Stream  => Stream,
         Buffer  => Buffer,
         Reactor => Aion.Runtime.Reactor_Of (Runtime),
         Future  => Future);
      Write_Registry.Put (Context, Put_Ok);

      if not Put_Ok then
         Done := Aion.Net.Count_Futures.Complete_Failure
           (Future, Aion.Errors.Capacity_Exceeded,
            "write registry is full", "Aion.Net.TCP_Stream.Async_Write");
         return Future;
      end if;

      Spawned := Aion.Runtime.Spawn (Runtime, Name, Run_Write'Access);
      if Aion.Runtime.Spawn_Results.Is_Err (Spawned) then
         Done := Aion.Net.Count_Futures.Complete_Failure
           (Future, Aion.Runtime.Spawn_Results.Error (Spawned));
      end if;
      return Future;
   end Async_Write;

   function Close
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Stream  : in out TCP_Stream) return Aion.Net.Operation_Results.Result_Type is
      Unreg : Aion.Reactor.Operation_Results.Result_Type;
      pragma Unreferenced (Unreg);
   begin
      if not Stream.Open then
         return Aion.Net.Operation_Results.Success (True);
      end if;

      begin
         Unreg := Aion.Reactor.Unregister
           (Aion.Runtime.Reactor_Of (Runtime), Stream.Resource);
      exception
         when others => null;
      end;

      GNAT.Sockets.Close_Socket (Stream.Socket);
      Stream.Open := False;
      return Aion.Net.Operation_Results.Success (True);
   exception
      when E : others =>
         Stream.Open := False;
         return Aion.Net.Operation_Results.Failure
           (Aion.Errors.Io_Error,
            "close failed: " & Ada.Exceptions.Exception_Message (E),
            "Aion.Net.TCP_Stream.Close");
   end Close;

   function Is_Open (Stream : TCP_Stream) return Boolean is
   begin
      return Stream.Open;
   end Is_Open;

   function Name_Of (Stream : TCP_Stream) return String is
   begin
      return US.To_String (Stream.Name);
   end Name_Of;

   function Peer_Of (Stream : TCP_Stream) return Aion.Net.Address.Network_Address is
   begin
      return Stream.Peer;
   end Peer_Of;

   function Resource_Of (Stream : TCP_Stream) return Aion.IO_Resource.IO_Resource is
   begin
      return Stream.Resource;
   end Resource_Of;

   function Image (Stream : TCP_Stream) return String is
   begin
      return "TCP_Stream(name=" & Name_Of (Stream) &
        ", open=" & Boolean'Image (Stream.Open) &
        ", peer=" & Aion.Net.Address.Image (Stream.Peer) & ")";
   end Image;

   function From_Accepted_Socket
     (Reactor : not null Aion.Reactor.Reactor_Service_Access;
      Socket  : GNAT.Sockets.Socket_Type;
      Peer    : Aion.Net.Address.Network_Address;
      Name    : String := "tcp-accepted") return Stream_Results.Result_Type is
      Reg : Aion.Reactor.Register_Results.Result_Type;
   begin
      Reg := Register_Stream (Reactor, Name);
      if Aion.Reactor.Register_Results.Is_Err (Reg) then
         return Stream_Results.Failure (Aion.Reactor.Register_Results.Error (Reg));
      end if;

      return Stream_Results.Success
        ((Socket   => Socket,
          Peer     => Peer,
          Resource => Aion.Reactor.Register_Results.Value (Reg),
          Open     => True,
          Name     => US.To_Unbounded_String (Name)));
   exception
      when E : others =>
         return Stream_Results.Failure
           (Aion.Errors.Io_Error,
            "accepted stream registration failed: " & Ada.Exceptions.Exception_Message (E),
            "Aion.Net.TCP_Stream.From_Accepted_Socket");
   end From_Accepted_Socket;

   function From_Accepted_Socket
     (Runtime : in out Aion.Runtime.Runtime_Handle;
      Socket  : GNAT.Sockets.Socket_Type;
      Peer    : Aion.Net.Address.Network_Address;
      Name    : String := "tcp-accepted") return Stream_Results.Result_Type is
   begin
      return From_Accepted_Socket
        (Aion.Runtime.Reactor_Of (Runtime), Socket, Peer, Name);
   end From_Accepted_Socket;

end Aion.Net.TCP_Stream;
