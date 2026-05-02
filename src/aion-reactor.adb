with Ada.Exceptions;
with Ada.Unchecked_Deallocation;
with Aion.Errors;

package body Aion.Reactor is
   use type Aion.IO_Token.Generator_Access;
   use type Aion.Reactor_Backend.Backend_Access;

   procedure Free_Tokens is new Ada.Unchecked_Deallocation
     (Aion.IO_Token.Generator, Aion.IO_Token.Generator_Access);
   procedure Free_Worker is new Ada.Unchecked_Deallocation
     (Reactor_Worker, Reactor_Worker_Access);
   procedure Free_Service is new Ada.Unchecked_Deallocation
     (Reactor_Service, Reactor_Service_Access);

   task body Reactor_Worker is
      Event : Aion.Reactor_Backend.Backend_Event := Aion.Reactor_Backend.Null_Event;
      Found : Boolean := False;
   begin
      Aion.Reactor_Backend.Mark_Worker_Started (Backend.all);

      loop
         Aion.Reactor_Backend.Wait (Backend.all, Event, Found);
         exit when not Found;

         Aion.Waker.Wake (Event.Waker);
         Aion.Reactor_Backend.Mark_Dispatched (Backend.all);
      end loop;

      Aion.Reactor_Backend.Mark_Worker_Stopped (Backend.all);
   exception
      when others =>
         Aion.Reactor_Backend.Mark_Worker_Stopped (Backend.all);
   end Reactor_Worker;

   function Create_Service
     (Max_Resources : Positive := 4_096;
      Max_Events    : Positive := 4_096;
      Backend       : Aion.Platform.Backend_Kind := Aion.Platform.Default_Backend)
      return Reactor_Service_Access is
   begin
      return new Reactor_Service'
        (Backend => Aion.Reactor_Backend.Create
          (Max_Resources => Max_Resources,
           Max_Events    => Max_Events,
           Kind          => Backend),
         Tokens  => new Aion.IO_Token.Generator,
         Worker  => null,
         Kind    => Backend);
   end Create_Service;

   function Start
     (Service : not null Reactor_Service_Access) return Operation_Results.Result_Type is
   begin
      if Service.Backend = null or else Service.Tokens = null then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "reactor service was not initialized",
            "Aion.Reactor.Start");
      end if;

      if Service.Worker /= null then
         return Operation_Results.Success (True);
      end if;

      Service.Worker := new Reactor_Worker (Backend => Service.Backend);
      return Operation_Results.Success (True);
   exception
      when Failure : others =>
         return Operation_Results.Failure
           (Aion.Errors.Runtime_Error,
            Ada.Exceptions.Exception_Name (Failure) & ": " &
              Ada.Exceptions.Exception_Message (Failure),
            "Aion.Reactor.Start");
   end Start;

   procedure Stop (Service : in out Reactor_Service) is
   begin
      if Service.Backend /= null then
         Aion.Reactor_Backend.Request_Stop (Service.Backend.all);
      end if;
   end Stop;

   procedure Destroy (Service : in out Reactor_Service_Access) is
   begin
      if Service = null then
         return;
      end if;

      Stop (Service.all);

      while Service.Worker /= null and then
        Aion.Reactor_Backend.Stats_Of (Service.Backend.all).Worker_Running
      loop
         delay 0.001;
      end loop;

      if Service.Worker /= null then
         Free_Worker (Service.Worker);
      end if;

      if Service.Tokens /= null then
         Free_Tokens (Service.Tokens);
      end if;

      if Service.Backend /= null then
         Aion.Reactor_Backend.Destroy (Service.Backend);
      end if;

      Free_Service (Service);
   end Destroy;

   function Register
     (Service  : not null Reactor_Service_Access;
      Handle   : Aion.IO_Resource.Native_Handle;
      Interest : Aion.Readiness.Readiness_Set;
      Waker    : Aion.Waker.Waker;
      Name     : String := "io-resource") return Register_Results.Result_Type is
      Token  : Aion.IO_Token.IO_Token := Aion.IO_Token.No_Token;
      Result : Aion.Reactor_Backend.Operation_Results.Result_Type;
   begin
      if Service.Backend = null or else Service.Tokens = null then
         return Register_Results.Failure
           (Aion.Errors.Invalid_State,
            "reactor service was not initialized",
            "Aion.Reactor.Register");
      end if;

      Service.Tokens.Next (Token);
      Result := Aion.Reactor_Backend.Register
        (Item     => Service.Backend,
         Token    => Token,
         Handle   => Handle,
         Interest => Interest,
         Waker    => Waker);

      if Aion.Reactor_Backend.Operation_Results.Is_Err (Result) then
         return Register_Results.Failure
           (Aion.Reactor_Backend.Operation_Results.Error (Result));
      end if;

      return Register_Results.Success
        (Aion.IO_Resource.Create
          (Token    => Token,
           Handle   => Handle,
           Name     => Name,
           Interest => Interest));
   end Register;

   function Unregister
     (Service  : not null Reactor_Service_Access;
      Resource : Aion.IO_Resource.IO_Resource) return Operation_Results.Result_Type is
   begin
      return Unregister (Service, Aion.IO_Resource.Token_Of (Resource));
   end Unregister;

   function Unregister
     (Service : not null Reactor_Service_Access;
      Token   : Aion.IO_Token.IO_Token) return Operation_Results.Result_Type is
      Result : Aion.Reactor_Backend.Operation_Results.Result_Type;
   begin
      if Service.Backend = null then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "reactor service was not initialized",
            "Aion.Reactor.Unregister");
      end if;

      Result := Aion.Reactor_Backend.Unregister (Service.Backend, Token);

      if Aion.Reactor_Backend.Operation_Results.Is_Err (Result) then
         return Operation_Results.Failure
           (Aion.Reactor_Backend.Operation_Results.Error (Result));
      end if;

      return Operation_Results.Success (True);
   end Unregister;

   function Update_Interest
     (Service  : not null Reactor_Service_Access;
      Resource : Aion.IO_Resource.IO_Resource;
      Interest : Aion.Readiness.Readiness_Set) return Operation_Results.Result_Type is
      Result : Aion.Reactor_Backend.Operation_Results.Result_Type;
   begin
      if Service.Backend = null then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "reactor service was not initialized",
            "Aion.Reactor.Update_Interest");
      end if;

      Result := Aion.Reactor_Backend.Update_Interest
        (Item     => Service.Backend,
         Token    => Aion.IO_Resource.Token_Of (Resource),
         Interest => Interest);

      if Aion.Reactor_Backend.Operation_Results.Is_Err (Result) then
         return Operation_Results.Failure
           (Aion.Reactor_Backend.Operation_Results.Error (Result));
      end if;

      return Operation_Results.Success (True);
   end Update_Interest;

   function Notify_Readiness
     (Service  : not null Reactor_Service_Access;
      Resource : Aion.IO_Resource.IO_Resource;
      Ready    : Aion.Readiness.Readiness_Set) return Operation_Results.Result_Type is
   begin
      return Notify_Readiness
        (Service => Service,
         Token   => Aion.IO_Resource.Token_Of (Resource),
         Ready   => Ready);
   end Notify_Readiness;

   function Notify_Readiness
     (Service : not null Reactor_Service_Access;
      Token   : Aion.IO_Token.IO_Token;
      Ready   : Aion.Readiness.Readiness_Set) return Operation_Results.Result_Type is
      Result : Aion.Reactor_Backend.Operation_Results.Result_Type;
   begin
      if Service.Backend = null then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_State,
            "reactor service was not initialized",
            "Aion.Reactor.Notify_Readiness");
      end if;

      Result := Aion.Reactor_Backend.Notify_Readiness
        (Item  => Service.Backend,
         Token => Token,
         Ready => Ready);

      if Aion.Reactor_Backend.Operation_Results.Is_Err (Result) then
         return Operation_Results.Failure
           (Aion.Reactor_Backend.Operation_Results.Error (Result));
      end if;

      return Operation_Results.Success (True);
   end Notify_Readiness;

   function Stats_Of (Service : Reactor_Service) return Reactor_Stats is
   begin
      if Service.Backend = null then
         return Reactor_Stats'(others => <>);
      end if;

      return Aion.Reactor_Backend.Stats_Of (Service.Backend.all);
   end Stats_Of;

   function Backend_Of (Service : Reactor_Service) return Aion.Platform.Backend_Kind is
   begin
      return Service.Kind;
   end Backend_Of;

   function Resource_Count_Of (Service : Reactor_Service) return Natural is
   begin
      if Service.Backend = null then
         return 0;
      end if;

      return Aion.Reactor_Backend.Resource_Count_Of (Service.Backend.all);
   end Resource_Count_Of;

   function Event_Depth_Of (Service : Reactor_Service) return Natural is
   begin
      if Service.Backend = null then
         return 0;
      end if;

      return Aion.Reactor_Backend.Event_Depth_Of (Service.Backend.all);
   end Event_Depth_Of;

   function Is_Stopping (Service : Reactor_Service) return Boolean is
   begin
      return Service.Backend = null or else
        Aion.Reactor_Backend.Is_Stopping (Service.Backend.all);
   end Is_Stopping;

end Aion.Reactor;
