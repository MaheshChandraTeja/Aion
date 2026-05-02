package body Aion.Cancel_Source is

   function Create
     (Name         : String := "cancel-source";
      Parent       : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Has_Deadline : Boolean := False;
      Deadline     : Aion.Clock.Instant := Aion.Clock.Epoch)
      return Cancel_Source is
   begin
      return
        (Token =>
           Aion.Cancel_Token.Create
             (Name         => Name,
              Parent       => Parent,
              Has_Deadline => Has_Deadline,
              Deadline     => Deadline));
   end Create;

   function With_Timeout
     (Name     : String;
      Parent   : Aion.Cancel_Token.Cancel_Token;
      Timeout  : Aion.Types.Milliseconds) return Cancel_Source is
   begin
      return Create
        (Name         => Name,
         Parent       => Parent,
         Has_Deadline => True,
         Deadline     => Aion.Clock.Add (Aion.Clock.Now, Timeout));
   end With_Timeout;

   function Token_Of
     (Source : Cancel_Source) return Aion.Cancel_Token.Cancel_Token is
   begin
      return Source.Token;
   end Token_Of;

   function Is_Valid (Source : Cancel_Source) return Boolean is
   begin
      return Aion.Cancel_Token.Is_Valid (Source.Token);
   end Is_Valid;

   function Is_Cancelled (Source : Cancel_Source) return Boolean is
   begin
      return Aion.Cancel_Token.Is_Cancelled (Source.Token);
   end Is_Cancelled;

   function Cancel
     (Source : Cancel_Source;
      Reason : String := "operation cancelled";
      Origin : String := "Aion.Cancel_Source.Cancel")
      return Operation_Results.Result_Type is
   begin
      return Aion.Cancel_Token.Cancel (Source.Token, Reason, Origin);
   end Cancel;

   function Child_Source
     (Source : Cancel_Source;
      Name   : String := "child-cancel-source")
      return Cancel_Source is
   begin
      return Create
        (Name   => Name,
         Parent => Source.Token);
   end Child_Source;

   function Image (Source : Cancel_Source) return String is
   begin
      return
        "Cancel_Source(" & Aion.Cancel_Token.Image (Source.Token) & ")";
   end Image;

end Aion.Cancel_Source;
