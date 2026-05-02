--  Network address helpers for Aion networking.

with Ada.Strings.Unbounded;
with GNAT.Sockets;
with Aion.Result;

package Aion.Net.Address is

   subtype Port_Number is Natural range 0 .. 65_535;

   package US renames Ada.Strings.Unbounded;

   type Network_Address is record
      Host     : US.Unbounded_String := US.To_Unbounded_String ("127.0.0.1");
      Port     : Port_Number := 0;
      Any_Host : Boolean := False;
   end record;

   package Address_Results is new Aion.Result.Generic_Result (Network_Address);

   function From
     (Host : String;
      Port : Port_Number) return Network_Address;

   function Localhost (Port : Port_Number) return Network_Address;
   function Any (Port : Port_Number) return Network_Address;

   function From_Sock_Addr
     (Address : GNAT.Sockets.Sock_Addr_Type) return Network_Address;

   function To_Sock_Addr
     (Address : Network_Address) return GNAT.Sockets.Sock_Addr_Type;

   function Host_Of (Address : Network_Address) return String;
   function Port_Of (Address : Network_Address) return Port_Number;
   function Is_Any (Address : Network_Address) return Boolean;
   function Is_Localhost (Address : Network_Address) return Boolean;
   function Is_Valid (Address : Network_Address) return Boolean;
   function Image (Address : Network_Address) return String;

end Aion.Net.Address;
