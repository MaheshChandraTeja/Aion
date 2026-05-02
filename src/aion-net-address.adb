with Ada.Strings.Fixed;

package body Aion.Net.Address is

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   function From
     (Host : String;
      Port : Port_Number) return Network_Address is
   begin
      return
        (Host     => US.To_Unbounded_String (Host),
         Port     => Port,
         Any_Host => Host = "0.0.0.0" or else Host = "*");
   end From;

   function Localhost (Port : Port_Number) return Network_Address is
   begin
      return From ("127.0.0.1", Port);
   end Localhost;

   function Any (Port : Port_Number) return Network_Address is
   begin
      return
        (Host     => US.To_Unbounded_String ("0.0.0.0"),
         Port     => Port,
         Any_Host => True);
   end Any;

   function From_Sock_Addr
     (Address : GNAT.Sockets.Sock_Addr_Type) return Network_Address is
   begin
      return From
        (GNAT.Sockets.Image (Address.Addr),
         Port_Number (Address.Port));
   end From_Sock_Addr;

   function To_Sock_Addr
     (Address : Network_Address) return GNAT.Sockets.Sock_Addr_Type is
      Host_Image : constant String := Host_Of (Address);
   begin
      if Address.Any_Host then
         return
           (Family => GNAT.Sockets.Family_Inet,
            Addr   => GNAT.Sockets.Any_Inet_Addr,
            Port   => GNAT.Sockets.Port_Type (Address.Port));
      else
         return
           (Family => GNAT.Sockets.Family_Inet,
            Addr   => GNAT.Sockets.Inet_Addr (Host_Image),
            Port   => GNAT.Sockets.Port_Type (Address.Port));
      end if;
   end To_Sock_Addr;

   function Host_Of (Address : Network_Address) return String is
   begin
      return US.To_String (Address.Host);
   end Host_Of;

   function Port_Of (Address : Network_Address) return Port_Number is
   begin
      return Address.Port;
   end Port_Of;

   function Is_Any (Address : Network_Address) return Boolean is
   begin
      return Address.Any_Host;
   end Is_Any;

   function Is_Localhost (Address : Network_Address) return Boolean is
      Host : constant String := Host_Of (Address);
   begin
      return Host = "127.0.0.1" or else Host = "localhost";
   end Is_Localhost;

   function Is_Valid (Address : Network_Address) return Boolean is
   begin
      return Address.Port > 0 and then Host_Of (Address)'Length > 0;
   end Is_Valid;

   function Image (Address : Network_Address) return String is
   begin
      return Host_Of (Address) & ":" & Trim (Port_Number'Image (Address.Port));
   end Image;

end Aion.Net.Address;
