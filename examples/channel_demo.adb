with Ada.Text_IO;
with Aion.Channel.Bounded;
with Aion.Sync;

procedure Channel_Demo is
   package Int_Channel is new Aion.Channel.Bounded.Generic_Bounded_Channel (Integer);

   Channel : Int_Channel.Bounded_Channel (Capacity => 8, Max_Waiters => 8);
   Send_F  : Aion.Sync.Boolean_Futures.Future_Handle;
   Recv_F  : Int_Channel.Message_Futures.Future_Handle;
   Recv_R  : Int_Channel.Message_Futures.Value_Results.Result_Type;
begin
   Ada.Text_IO.Put_Line ("Aion channel demo");

   Send_F := Int_Channel.Send (Channel, 2026);
   pragma Unreferenced (Send_F);

   Recv_F := Int_Channel.Receive (Channel);
   Recv_R := Int_Channel.Message_Futures.Await (Recv_F);

   if Int_Channel.Message_Futures.Value_Results.Is_Ok (Recv_R) then
      Ada.Text_IO.Put_Line
        ("received=" & Integer'Image (Int_Channel.Message_Futures.Value_Results.Value (Recv_R)));
   else
      Ada.Text_IO.Put_Line ("receive failed");
   end if;
end Channel_Demo;
