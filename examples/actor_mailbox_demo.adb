with Ada.Text_IO;
with Aion.Actor;
with Aion.Sync;

procedure Actor_Mailbox_Demo is
   procedure Print_Message (Message : in Integer) is
   begin
      Ada.Text_IO.Put_Line ("actor handled" & Integer'Image (Message));
   end Print_Message;

   package Int_Actor is new Aion.Actor.Generic_Actor (Integer, Print_Message);
   Mailbox : Int_Actor.Actor_Mailbox (Capacity => 16, Max_Waiters => 8);
   Result  : Aion.Sync.Boolean_Results.Result_Type;
begin
   Ada.Text_IO.Put_Line ("Aion actor mailbox demo");

   declare
      F1 : constant Aion.Sync.Boolean_Futures.Future_Handle := Int_Actor.Send (Mailbox, 1);
      F2 : constant Aion.Sync.Boolean_Futures.Future_Handle := Int_Actor.Send (Mailbox, 2);
      pragma Unreferenced (F1, F2);
   begin
      null;
   end;

   Result := Int_Actor.Drain (Mailbox);
   if Aion.Sync.Boolean_Results.Is_Ok (Result) then
      Ada.Text_IO.Put_Line ("mailbox drained");
   else
      Ada.Text_IO.Put_Line ("mailbox drain failed");
   end if;
end Actor_Mailbox_Demo;
