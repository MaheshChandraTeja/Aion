with Ada.Text_IO;
with Aion.Block_On;
with Aion.Errors;
with Aion.Net;
with Aion.Net.Address;
with Aion.Net.TCP_Listener;
with Aion.Net.TCP_Stream;
with Aion.Runtime;
with Aion.Runtime.Builder;

procedure Echo_Server is
   package Stream_Block is new Aion.Block_On.Generic_Block_On
     (Aion.Net.TCP_Stream.Stream_Futures);
   package Buffer_Block is new Aion.Block_On.Generic_Block_On
     (Aion.Net.Buffer_Futures);
   package Count_Block is new Aion.Block_On.Generic_Block_On
     (Aion.Net.Count_Futures);

   function Make_Runtime return Aion.Runtime.Runtime_Handle is
   begin
      return Aion.Runtime.Builder.Build
        (Aion.Runtime.Builder.With_Workers
           (Aion.Runtime.Builder.New_Builder, 4));
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Started : Aion.Runtime.Operation_Results.Result_Type;
   Bound   : Aion.Net.TCP_Listener.Listener_Results.Result_Type;

   Listener : Aion.Net.TCP_Listener.TCP_Listener :=
     Aion.Net.TCP_Listener.Null_Listener;
   Stream   : Aion.Net.TCP_Stream.TCP_Stream :=
     Aion.Net.TCP_Stream.Null_Stream;
begin
   Started := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line
        ("runtime failed: " &
         Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (Started)));
      return;
   end if;

   Bound := Aion.Net.TCP_Listener.Bind
     (Runtime, Aion.Net.Address.Localhost (9090), Name => "aion-echo-server");

   if Aion.Net.TCP_Listener.Listener_Results.Is_Err (Bound) then
      Ada.Text_IO.Put_Line
        ("bind failed: " &
         Aion.Errors.Image (Aion.Net.TCP_Listener.Listener_Results.Error (Bound)));
   else
      Listener := Aion.Net.TCP_Listener.Listener_Results.Value (Bound);
      Ada.Text_IO.Put_Line ("echo server listening on 127.0.0.1:9090");
      Ada.Text_IO.Put_Line ("waiting for one client, then echoing one message...");

      declare
         Accept_Future : constant Aion.Net.TCP_Stream.Stream_Futures.Future_Handle :=
           Aion.Net.TCP_Listener.Async_Accept
             (Runtime, Listener, Timeout => 60_000, Name => "echo-accept");
         Accepted : constant Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Result_Type :=
           Stream_Block.Run_Timeout (Accept_Future, 60_000);
      begin
         if Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Is_Err (Accepted) then
            Ada.Text_IO.Put_Line
              ("accept failed: " &
               Aion.Errors.Image
                 (Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Error (Accepted)));
         else
            Stream := Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Value (Accepted);
            Ada.Text_IO.Put_Line
              ("client connected: " & Aion.Net.TCP_Stream.Image (Stream));

            declare
               Read_Future : constant Aion.Net.Buffer_Futures.Future_Handle :=
                 Aion.Net.TCP_Stream.Async_Read
                   (Runtime,
                    Stream,
                    Max_Bytes => 4_096,
                    Timeout   => 10_000,
                    Name      => "echo-read");
               Read_Result : constant Aion.Net.Buffer_Futures.Value_Results.Result_Type :=
                 Buffer_Block.Run_Timeout (Read_Future, 10_000);
            begin
               if Aion.Net.Buffer_Futures.Value_Results.Is_Err (Read_Result) then
                  Ada.Text_IO.Put_Line
                    ("read failed: " &
                     Aion.Errors.Image
                       (Aion.Net.Buffer_Futures.Value_Results.Error (Read_Result)));
               else
                  declare
                     Payload : constant Aion.Net.Net_Buffer :=
                       Aion.Net.Buffer_Futures.Value_Results.Value (Read_Result);
                     Write_Future : constant Aion.Net.Count_Futures.Future_Handle :=
                       Aion.Net.TCP_Stream.Async_Write
                         (Runtime,
                          Stream,
                          Payload,
                          Timeout => 10_000,
                          Name    => "echo-write");
                     Write_Result : constant Aion.Net.Count_Futures.Value_Results.Result_Type :=
                       Count_Block.Run_Timeout (Write_Future, 10_000);
                  begin
                     if Aion.Net.Count_Futures.Value_Results.Is_Err (Write_Result) then
                        Ada.Text_IO.Put_Line
                          ("write failed: " &
                           Aion.Errors.Image
                             (Aion.Net.Count_Futures.Value_Results.Error (Write_Result)));
                     else
                        Ada.Text_IO.Put_Line
                          ("echoed bytes:" &
                           Natural'Image
                             (Aion.Net.Count_Futures.Value_Results.Value (Write_Result)));
                        Ada.Text_IO.Put_Line
                          ("payload: " & Aion.Net.To_String (Payload));
                     end if;
                  end;
               end if;
            end;
         end if;
      end;
   end if;

   declare
      Close_Stream : Aion.Net.Operation_Results.Result_Type;
      Close_Listen : Aion.Net.Operation_Results.Result_Type;
      Shutdown_Result : Aion.Runtime.Operation_Results.Result_Type;
   begin
      if Aion.Net.TCP_Stream.Is_Open (Stream) then
         Close_Stream := Aion.Net.TCP_Stream.Close (Runtime, Stream);
         if Aion.Net.Operation_Results.Is_Err (Close_Stream) then
            Ada.Text_IO.Put_Line
              ("stream close failed: " &
               Aion.Errors.Image (Aion.Net.Operation_Results.Error (Close_Stream)));
         end if;
      end if;

      if Aion.Net.TCP_Listener.Is_Open (Listener) then
         Close_Listen := Aion.Net.TCP_Listener.Close (Runtime, Listener);
         if Aion.Net.Operation_Results.Is_Err (Close_Listen) then
            Ada.Text_IO.Put_Line
              ("listener close failed: " &
               Aion.Errors.Image (Aion.Net.Operation_Results.Error (Close_Listen)));
         end if;
      end if;

      Shutdown_Result := Aion.Runtime.Shutdown (Runtime);
      if Aion.Runtime.Operation_Results.Is_Err (Shutdown_Result) then
         Ada.Text_IO.Put_Line
           ("shutdown failed: " &
            Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (Shutdown_Result)));
      end if;
   end;
end Echo_Server;
