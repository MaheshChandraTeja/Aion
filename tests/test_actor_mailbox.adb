with Aion.Actor;
with Aion.Sync;
with Test_Support;

procedure Test_Actor_Mailbox is
   protected Counter is
      procedure Add (Value : Integer);
      function Value return Integer;
   private
      Current : Integer := 0;
   end Counter;

   protected body Counter is
      procedure Add (Value : Integer) is
      begin
         Current := Current + Value;
      end Add;
      function Value return Integer is
      begin
         return Current;
      end Value;
   end Counter;

   procedure Handle (Message : in Integer) is
   begin
      Counter.Add (Message);
   end Handle;

   package Int_Actor is new Aion.Actor.Generic_Actor (Integer, Handle);
   M : Int_Actor.Actor_Mailbox (Capacity => 8, Max_Waiters => 4);
   Result : Aion.Sync.Boolean_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Actor.Mailbox");

   declare
      F1 : constant Aion.Sync.Boolean_Futures.Future_Handle := Int_Actor.Send (M, 5);
      F2 : constant Aion.Sync.Boolean_Futures.Future_Handle := Int_Actor.Send (M, 6);
      pragma Unreferenced (F1, F2);
   begin
      null;
   end;

   Result := Int_Actor.Drain (M);
   Test_Support.Assert (Aion.Sync.Boolean_Results.Is_Ok (Result), "actor drain should succeed");
   Test_Support.Assert (Counter.Value = 11, "actor handler should process messages serially");

   Test_Support.Pass ("actor mailbox dispatch works");
end Test_Actor_Mailbox;
