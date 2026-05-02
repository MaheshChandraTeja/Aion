with Ada.Text_IO;
with Aion.Block_On;
with Aion.Errors;
with Aion.Net;
with Aion.Net.Address;
with Aion.Net.TCP_Stream;
with Aion.Runtime;
with Aion.Runtime.Builder;
with Aion.Time;

procedure TCP_Timeout_Demo is
   package Stream_Block is new Aion.Block_On.Generic_Block_On
     (Aion.Net.TCP_Stream.Stream_Futures);

   Runtime : Aion.Runtime.Runtime_Handle :=
     Aion.Runtime.Builder.Build
       (Aion.Runtime.Builder.With_Workers
          (Aion.Runtime.Builder.New_Builder, 2));
   Started : Aion.Runtime.Operation_Results.Result_Type;
   Future  : Aion.Net.TCP_Stream.Stream_Futures.Future_Handle;
   Result  : Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Result_Type;
begin
   Started := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line
        ("runtime failed: " &
         Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (Started)));
      return;
   end if;

   Future := Aion.Net.TCP_Stream.Async_Connect
     (Runtime, Aion.Net.Address.From ("127.0.0.1", 6553), Name => "timeout-demo-connect");
   Result := Stream_Block.Run_Timeout (Future, Aion.Time.Ms (250));

   if Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Is_Err (Result) then
      Ada.Text_IO.Put_Line
        ("connect did not complete successfully within demo policy: " &
         Aion.Errors.Image (Aion.Net.TCP_Stream.Stream_Futures.Value_Results.Error (Result)));
   end if;

   declare
      Shutdown_Result : constant Aion.Runtime.Operation_Results.Result_Type :=
        Aion.Runtime.Shutdown (Runtime);
   begin
      if Aion.Runtime.Operation_Results.Is_Err (Shutdown_Result) then
         Ada.Text_IO.Put_Line
           ("shutdown failed: " &
            Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (Shutdown_Result)));
      end if;
   end;
end TCP_Timeout_Demo;
