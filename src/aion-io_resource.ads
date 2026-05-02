--  Public description of an I/O resource registered with the Aion reactor.

with Ada.Strings.Unbounded;
with Interfaces;
with Aion.IO_Token;
with Aion.Readiness;
with Aion.Types;

package Aion.IO_Resource is

   type Native_Handle is new Interfaces.Integer_64;
   Invalid_Native_Handle : constant Native_Handle := -1;

   type IO_Resource is private;

   Null_Resource : constant IO_Resource;

   function Create
     (Token    : Aion.IO_Token.IO_Token;
      Handle   : Native_Handle;
      Name     : String;
      Interest : Aion.Readiness.Readiness_Set) return IO_Resource;

   function Is_Valid (Resource : IO_Resource) return Boolean;
   function Token_Of (Resource : IO_Resource) return Aion.IO_Token.IO_Token;
   function Handle_Of (Resource : IO_Resource) return Native_Handle;
   function Name_Of (Resource : IO_Resource) return String;
   function Interest_Of (Resource : IO_Resource) return Aion.Readiness.Readiness_Set;
   function State_Of (Resource : IO_Resource) return Aion.Types.Resource_State;

   function With_Interest
     (Resource : IO_Resource;
      Interest : Aion.Readiness.Readiness_Set) return IO_Resource;
   function With_State
     (Resource : IO_Resource;
      State    : Aion.Types.Resource_State) return IO_Resource;

   function Image (Handle : Native_Handle) return String;
   function Image (Resource : IO_Resource) return String;

private
   package US renames Ada.Strings.Unbounded;

   type IO_Resource is record
      Token    : Aion.IO_Token.IO_Token := Aion.IO_Token.No_Token;
      Handle   : Native_Handle := Invalid_Native_Handle;
      Name     : US.Unbounded_String := US.Null_Unbounded_String;
      Interest : Aion.Readiness.Readiness_Set := Aion.Readiness.None;
      State    : Aion.Types.Resource_State := Aion.Types.Resource_Closed;
   end record;

   Null_Resource : constant IO_Resource :=
     (Token    => Aion.IO_Token.No_Token,
      Handle   => Invalid_Native_Handle,
      Name     => US.Null_Unbounded_String,
      Interest => Aion.Readiness.None,
      State    => Aion.Types.Resource_Closed);

end Aion.IO_Resource;
