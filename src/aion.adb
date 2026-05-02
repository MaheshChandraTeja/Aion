package body Aion is

   protected Runtime_State is
      procedure Set_Initialized (Value : Boolean);
      function Initialized return Boolean;
   private
      Current : Boolean := False;
   end Runtime_State;

   protected body Runtime_State is
      procedure Set_Initialized (Value : Boolean) is
      begin
         Current := Value;
      end Set_Initialized;

      function Initialized return Boolean is
      begin
         return Current;
      end Initialized;
   end Runtime_State;

   function Name return String is
   begin
      return Library_Name;
   end Name;

   function Description return String is
   begin
      return "Aion is a structured asynchronous runtime and scheduler foundation for Ada.";
   end Description;

   procedure Initialize is
   begin
      Runtime_State.Set_Initialized (True);
   end Initialize;

   procedure Finalize is
   begin
      Runtime_State.Set_Initialized (False);
   end Finalize;

   function Is_Initialized return Boolean is
   begin
      return Runtime_State.Initialized;
   end Is_Initialized;

end Aion;
