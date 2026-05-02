--  Shutdown utilities shared by runtime and structured-concurrency modules.
--
--  Module 9 extends the original shutdown request model with a lightweight
--  shutdown tree that owns a cancellation source. Runtime-facing code can use
--  the request portion exactly as before, while scopes/task groups can attach
--  to the tree token for graceful shutdown propagation.

with Aion.Cancel_Source;
with Aion.Cancel_Token;
with Aion.Config;
with Aion.Result;
with Aion.Types;

package Aion.Shutdown is

   type Shutdown_Request is tagged private;
   type Shutdown_Tree is limited private;

   package Validation_Results is new Aion.Result.Generic_Result (Boolean);

   function From_Config
     (Config : Aion.Config.Runtime_Config) return Shutdown_Request;

   function Create
     (Mode       : Aion.Types.Shutdown_Mode;
      Timeout_Ms : Aion.Types.Milliseconds) return Shutdown_Request;

   function Mode_Of (Request : Shutdown_Request) return Aion.Types.Shutdown_Mode;
   function Timeout_Of (Request : Shutdown_Request) return Aion.Types.Milliseconds;
   function Is_Immediate (Request : Shutdown_Request) return Boolean;
   function Is_Graceful (Request : Shutdown_Request) return Boolean;

   function Validate
     (Request : Shutdown_Request) return Validation_Results.Result_Type;

   procedure Initialize_Tree
     (Tree : in out Shutdown_Tree;
      Name : String := "shutdown-tree";

      Parent : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token);

   function Request_Shutdown
     (Tree    : in out Shutdown_Tree;
      Request : Shutdown_Request;
      Reason  : String := "shutdown requested")
      return Validation_Results.Result_Type;

   function Token_Of
     (Tree : Shutdown_Tree) return Aion.Cancel_Token.Cancel_Token;

   function Source_Of
     (Tree : Shutdown_Tree) return Aion.Cancel_Source.Cancel_Source;

   function Is_Requested (Tree : Shutdown_Tree) return Boolean;

   function Image (Request : Shutdown_Request) return String;

private
   type Shutdown_Request is tagged record
      Mode       : Aion.Types.Shutdown_Mode := Aion.Types.Shutdown_Graceful;
      Timeout_Ms : Aion.Types.Milliseconds := 30_000;
   end record;

   type Shutdown_Tree is limited record
      Source : Aion.Cancel_Source.Cancel_Source :=
        Aion.Cancel_Source.Null_Source;
   end record;

end Aion.Shutdown;
