with Ada.Strings.Fixed;

package body Aion.IO_Resource is
   use type Aion.Types.Resource_State;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function Create
     (Token    : Aion.IO_Token.IO_Token;
      Handle   : Native_Handle;
      Name     : String;
      Interest : Aion.Readiness.Readiness_Set) return IO_Resource is
   begin
      if not Aion.IO_Token.Is_Valid (Token) or else Handle = Invalid_Native_Handle then
         return Null_Resource;
      end if;

      return
        (Token    => Token,
         Handle   => Handle,
         Name     => US.To_Unbounded_String (Name),
         Interest => Interest,
         State    => Aion.Types.Resource_Open);
   end Create;

   function Is_Valid (Resource : IO_Resource) return Boolean is
   begin
      return
        Aion.IO_Token.Is_Valid (Resource.Token) and then
        Resource.Handle /= Invalid_Native_Handle and then
        Resource.State /= Aion.Types.Resource_Closed;
   end Is_Valid;

   function Token_Of (Resource : IO_Resource) return Aion.IO_Token.IO_Token is
   begin
      return Resource.Token;
   end Token_Of;

   function Handle_Of (Resource : IO_Resource) return Native_Handle is
   begin
      return Resource.Handle;
   end Handle_Of;

   function Name_Of (Resource : IO_Resource) return String is
   begin
      return US.To_String (Resource.Name);
   end Name_Of;

   function Interest_Of (Resource : IO_Resource) return Aion.Readiness.Readiness_Set is
   begin
      return Resource.Interest;
   end Interest_Of;

   function State_Of (Resource : IO_Resource) return Aion.Types.Resource_State is
   begin
      return Resource.State;
   end State_Of;

   function With_Interest
     (Resource : IO_Resource;
      Interest : Aion.Readiness.Readiness_Set) return IO_Resource is
      Copy : IO_Resource := Resource;
   begin
      Copy.Interest := Interest;
      return Copy;
   end With_Interest;

   function With_State
     (Resource : IO_Resource;
      State    : Aion.Types.Resource_State) return IO_Resource is
      Copy : IO_Resource := Resource;
   begin
      Copy.State := State;
      return Copy;
   end With_State;

   function Image (Handle : Native_Handle) return String is
   begin
      if Handle = Invalid_Native_Handle then
         return "native-handle:invalid";
      end if;

      return "native-handle:" & Trim (Native_Handle'Image (Handle));
   end Image;

   function Image (Resource : IO_Resource) return String is
   begin
      if not Is_Valid (Resource) then
         return "IO_Resource(null)";
      end if;

      return
        "IO_Resource(token=" & Aion.IO_Token.Image (Resource.Token) &
        ", handle=" & Image (Resource.Handle) &
        ", name=""" & US.To_String (Resource.Name) & """" &
        ", interest=" & Aion.Readiness.Image (Resource.Interest) &
        ", state=" & Aion.Types.Image (Resource.State) & ")";
   end Image;

end Aion.IO_Resource;
