--  Runtime-owned I/O reactor service.
--
--  Aion.Reactor exposes stable registration and readiness notification APIs
--  while delegating backend details to Aion.Reactor_Backend. The service is
--  intended to be owned by Aion.Runtime, not manually juggled by application
--  code unless the caller is deliberately building advanced integrations.

with Aion.IO_Resource;
with Aion.IO_Token;
with Aion.Platform;
with Aion.Readiness;
with Aion.Reactor_Backend;
with Aion.Result;
with Aion.Waker;

package Aion.Reactor is

   type Reactor_Service is limited private;
   type Reactor_Service_Access is access all Reactor_Service;

   subtype Reactor_Stats is Aion.Reactor_Backend.Backend_Stats;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);
   package Register_Results is new Aion.Result.Generic_Result
     (Aion.IO_Resource.IO_Resource);

   function Create_Service
     (Max_Resources : Positive := 4_096;
      Max_Events    : Positive := 4_096;
      Backend       : Aion.Platform.Backend_Kind := Aion.Platform.Default_Backend)
      return Reactor_Service_Access;

   function Start
     (Service : not null Reactor_Service_Access) return Operation_Results.Result_Type;

   procedure Stop (Service : in out Reactor_Service);
   procedure Destroy (Service : in out Reactor_Service_Access);

   function Register
     (Service  : not null Reactor_Service_Access;
      Handle   : Aion.IO_Resource.Native_Handle;
      Interest : Aion.Readiness.Readiness_Set;
      Waker    : Aion.Waker.Waker;
      Name     : String := "io-resource") return Register_Results.Result_Type;

   function Unregister
     (Service  : not null Reactor_Service_Access;
      Resource : Aion.IO_Resource.IO_Resource) return Operation_Results.Result_Type;

   function Unregister
     (Service : not null Reactor_Service_Access;
      Token   : Aion.IO_Token.IO_Token) return Operation_Results.Result_Type;

   function Update_Interest
     (Service  : not null Reactor_Service_Access;
      Resource : Aion.IO_Resource.IO_Resource;
      Interest : Aion.Readiness.Readiness_Set) return Operation_Results.Result_Type;

   function Notify_Readiness
     (Service  : not null Reactor_Service_Access;
      Resource : Aion.IO_Resource.IO_Resource;
      Ready    : Aion.Readiness.Readiness_Set) return Operation_Results.Result_Type;

   function Notify_Readiness
     (Service : not null Reactor_Service_Access;
      Token   : Aion.IO_Token.IO_Token;
      Ready   : Aion.Readiness.Readiness_Set) return Operation_Results.Result_Type;

   function Stats_Of (Service : Reactor_Service) return Reactor_Stats;
   function Backend_Of (Service : Reactor_Service) return Aion.Platform.Backend_Kind;
   function Resource_Count_Of (Service : Reactor_Service) return Natural;
   function Event_Depth_Of (Service : Reactor_Service) return Natural;
   function Is_Stopping (Service : Reactor_Service) return Boolean;

   function Image (Stats : Reactor_Stats) return String renames Aion.Reactor_Backend.Image;

private
   task type Reactor_Worker
     (Backend : not null Aion.Reactor_Backend.Backend_Access);

   type Reactor_Worker_Access is access Reactor_Worker;

   type Reactor_Service is limited record
      Backend  : Aion.Reactor_Backend.Backend_Access := null;
      Tokens   : Aion.IO_Token.Generator_Access := null;
      Worker   : Reactor_Worker_Access := null;
      Kind     : Aion.Platform.Backend_Kind := Aion.Platform.Backend_Portable_Select;
   end record;

end Aion.Reactor;
