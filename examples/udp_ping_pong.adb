with Ada.Text_IO;
with Aion.Block_On;
with Aion.Errors;
with Aion.Net;
with Aion.Net.Address;
with Aion.Net.UDP;
with Aion.Runtime;
with Aion.Runtime.Builder;

procedure UDP_Ping_Pong is
   package Count_Block is new Aion.Block_On.Generic_Block_On (Aion.Net.Count_Futures);

   Runtime : Aion.Runtime.Runtime_Handle :=
     Aion.Runtime.Builder.Build
       (Aion.Runtime.Builder.With_Workers
          (Aion.Runtime.Builder.New_Builder, 2));
   Started : Aion.Runtime.Operation_Results.Result_Type;
   Bound   : Aion.Net.UDP.Socket_Results.Result_Type;
begin
   Started := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line
        ("runtime failed: " &
         Aion.Errors.Image (Aion.Runtime.Operation_Results.Error (Started)));
      return;
   end if;

   Bound := Aion.Net.UDP.Bind
     (Runtime, Aion.Net.Address.Localhost (0), Name => "udp-ping-pong");

   if Aion.Net.UDP.Socket_Results.Is_Ok (Bound) then
      declare
         Socket : constant Aion.Net.UDP.UDP_Socket :=
           Aion.Net.UDP.Socket_Results.Value (Bound);
         Future : constant Aion.Net.Count_Futures.Future_Handle :=
           Aion.Net.UDP.Async_Send_To
             (Runtime,
              Socket,
              Aion.Net.Address.Localhost (9091),
              Aion.Net.From_String ("ping"));
         Sent : constant Aion.Net.Count_Futures.Value_Results.Result_Type :=
           Count_Block.Run_Timeout (Future, 500);
      begin
         if Aion.Net.Count_Futures.Value_Results.Is_Ok (Sent) then
            Ada.Text_IO.Put_Line
              ("udp sent bytes:" &
               Natural'Image (Aion.Net.Count_Futures.Value_Results.Value (Sent)));
         end if;
      end;
   else
      Ada.Text_IO.Put_Line
        ("UDP bind failed: " &
         Aion.Errors.Image (Aion.Net.UDP.Socket_Results.Error (Bound)));
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
end UDP_Ping_Pong;
