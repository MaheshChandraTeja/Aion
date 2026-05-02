with Aion.Errors;

package body Aion.Shutdown is
   use type Aion.Types.Milliseconds;
   use type Aion.Types.Shutdown_Mode;

   function From_Config
     (Config : Aion.Config.Runtime_Config) return Shutdown_Request is
   begin
      return Create
        (Mode       => Aion.Config.Shutdown_Mode_Of (Config),
         Timeout_Ms => Aion.Config.Shutdown_Timeout_Of (Config));
   end From_Config;

   function Create
     (Mode       : Aion.Types.Shutdown_Mode;
      Timeout_Ms : Aion.Types.Milliseconds) return Shutdown_Request is
   begin
      return Shutdown_Request'(Mode => Mode, Timeout_Ms => Timeout_Ms);
   end Create;

   function Mode_Of (Request : Shutdown_Request) return Aion.Types.Shutdown_Mode is
   begin
      return Request.Mode;
   end Mode_Of;

   function Timeout_Of (Request : Shutdown_Request) return Aion.Types.Milliseconds is
   begin
      return Request.Timeout_Ms;
   end Timeout_Of;

   function Is_Immediate (Request : Shutdown_Request) return Boolean is
   begin
      return Request.Mode = Aion.Types.Shutdown_Immediate;
   end Is_Immediate;

   function Is_Graceful (Request : Shutdown_Request) return Boolean is
   begin
      return Request.Mode = Aion.Types.Shutdown_Graceful;
   end Is_Graceful;

   function Validate
     (Request : Shutdown_Request) return Validation_Results.Result_Type is
   begin
      if Request.Timeout_Ms > Aion.Config.Max_Shutdown_Timeout_Ms then
         return Validation_Results.Failure
           (Aion.Errors.Configuration_Error,
            "shutdown timeout exceeds configured maximum",
            "Aion.Shutdown.Validate");
      end if;

      return Validation_Results.Success (True);
   end Validate;

   procedure Initialize_Tree
     (Tree : in out Shutdown_Tree;
      Name : String := "shutdown-tree";
      Parent : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token) is
   begin
      Tree.Source := Aion.Cancel_Source.Create
        (Name   => Name & ".cancel",
         Parent => Parent);
   end Initialize_Tree;

   function Request_Shutdown
     (Tree    : in out Shutdown_Tree;
      Request : Shutdown_Request;
      Reason  : String := "shutdown requested")
      return Validation_Results.Result_Type
   is
      V : constant Validation_Results.Result_Type := Validate (Request);
      R : Aion.Cancel_Source.Operation_Results.Result_Type;
   begin
      if Validation_Results.Is_Err (V) then
         return V;
      end if;

      R := Aion.Cancel_Source.Cancel
        (Tree.Source,
         Reason & " (" & Image (Request) & ")",
         "Aion.Shutdown.Request_Shutdown");

      if Aion.Cancel_Source.Operation_Results.Is_Err (R) then
         return Validation_Results.Failure
           (Aion.Cancel_Source.Operation_Results.Error (R));
      end if;

      return Validation_Results.Success (True);
   end Request_Shutdown;

   function Token_Of
     (Tree : Shutdown_Tree) return Aion.Cancel_Token.Cancel_Token is
   begin
      return Aion.Cancel_Source.Token_Of (Tree.Source);
   end Token_Of;

   function Source_Of
     (Tree : Shutdown_Tree) return Aion.Cancel_Source.Cancel_Source is
   begin
      return Tree.Source;
   end Source_Of;

   function Is_Requested (Tree : Shutdown_Tree) return Boolean is
   begin
      return Aion.Cancel_Source.Is_Cancelled (Tree.Source);
   end Is_Requested;

   function Image (Request : Shutdown_Request) return String is
   begin
      return
        "Shutdown_Request(mode=" & Aion.Types.Image (Request.Mode) &
        ", timeout=" & Aion.Types.Image (Request.Timeout_Ms) & "ms)";
   end Image;

end Aion.Shutdown;
