with Ada.Text_IO;
with Aion.Block_On;
with Aion.Errors;
with Aion.Net;
with Aion.Net.Address;
with Aion.Net.TCP_Stream;
with Aion.Runtime;
with Aion.Runtime.Builder;

procedure Echo_Client is
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
   Stream  : Aion.Net.TCP_Stream.TCP_Stream := Aion.Net.TCP_Stream.Null_Stream;
begin
   Started := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line
        ("runtime failed: " &
         Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (Started)));
      return;
   end if;

   declare
      Connect_Future : constant Aion.Net.TCP_Stream.Stream_Futures.Future_Handle :=
        Aion.Net.TCP_Stream.Async_Connect
          (Runtime, Aion.Net.Address.Localhost (9090), Name => "echo-client-connect");
      Connect_Result : constant Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Result_Type :=
        Stream_Block.Run_Timeout (Connect_Future, 5_000);
   begin
      if Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Is_Err (Connect_Result) then
         Ada.Text_IO.Put_Line
           ("connect failed: " &
            Aion.Errors.Image
              (Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Error (Connect_Result)));
      else
         Stream := Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Value (Connect_Result);
         Ada.Text_IO.Put_Line ("connected: " & Aion.Net.TCP_Stream.Image (Stream));

         declare
            Message : constant String := "hello from Aion";
            Write_Future : constant Aion.Net.Count_Futures.Future_Handle :=
              Aion.Net.TCP_Stream.Async_Write
                (Runtime,
                 Stream,
                 Aion.Net.From_String (Message),
                 Timeout => 5_000,
                 Name    => "echo-client-write");
            Write_Result : constant Aion.Net.Count_Futures.Value_Results.Result_Type :=
              Count_Block.Run_Timeout (Write_Future, 5_000);
         begin
            if Aion.Net.Count_Futures.Value_Results.Is_Err (Write_Result) then
               Ada.Text_IO.Put_Line
                 ("write failed: " &
                  Aion.Errors.Image
                    (Aion.Net.Count_Futures.Value_Results.Error (Write_Result)));
            else
               Ada.Text_IO.Put_Line
                 ("sent bytes:" &
                  Natural'Image
                    (Aion.Net.Count_Futures.Value_Results.Value (Write_Result)));

               declare
                  Read_Future : constant Aion.Net.Buffer_Futures.Future_Handle :=
                    Aion.Net.TCP_Stream.Async_Read
                      (Runtime,
                       Stream,
                       Max_Bytes => 4_096,
                       Timeout   => 5_000,
                       Name      => "echo-client-read");
                  Read_Result : constant Aion.Net.Buffer_Futures.Value_Results.Result_Type :=
                    Buffer_Block.Run_Timeout (Read_Future, 5_000);
               begin
                  if Aion.Net.Buffer_Futures.Value_Results.Is_Err (Read_Result) then
                     Ada.Text_IO.Put_Line
                       ("read failed: " &
                        Aion.Errors.Image
                          (Aion.Net.Buffer_Futures.Value_Results.Error (Read_Result)));
                  else
                     Ada.Text_IO.Put_Line
                       ("echo reply: " &
                        Aion.Net.To_String
                          (Aion.Net.Buffer_Futures.Value_Results.Value (Read_Result)));
                  end if;
               end;
            end if;
         end;
      end if;
   end;

   declare
      Close_Result : Aion.Net.Operation_Results.Result_Type;
      Shutdown_Result : Aion.Runtime.Operation_Results.Result_Type;
   begin
      if Aion.Net.TCP_Stream.Is_Open (Stream) then
         Close_Result := Aion.Net.TCP_Stream.Close (Runtime, Stream);
         if Aion.Net.Operation_Results.Is_Err (Close_Result) then
            Ada.Text_IO.Put_Line
              ("close failed: " &
               Aion.Errors.Image (Aion.Net.Operation_Results.Error (Close_Result)));
         end if;
      end if;

      Shutdown_Result := Aion.Runtime.Shutdown (Runtime);
      if Aion.Runtime.Operation_Results.Is_Err (Shutdown_Result) then
         Ada.Text_IO.Put_Line
           ("shutdown failed: " &
            Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (Shutdown_Result)));
      end if;
   end;
end Echo_Client;
