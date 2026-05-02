with Test_Support;
with Aion.Cancel_Token;
with Aion.Shutdown;
with Aion.Types;

procedure Test_Runtime_Structured_Shutdown is
   Tree : Aion.Shutdown.Shutdown_Tree;
   Request : constant Aion.Shutdown.Shutdown_Request :=
     Aion.Shutdown.Create
       (Mode       => Aion.Types.Shutdown_Graceful,
        Timeout_Ms => 1_000);
   R : Aion.Shutdown.Validation_Results.Result_Type;
begin
   Test_Support.Section ("runtime structured shutdown");

   Aion.Shutdown.Initialize_Tree (Tree, "runtime-tree");
   Test_Support.Assert
     (not Aion.Shutdown.Is_Requested (Tree),
      "shutdown tree should start unrequested");

   R := Aion.Shutdown.Request_Shutdown
     (Tree,
      Request,
      "unit shutdown");

   Test_Support.Assert
     (Aion.Shutdown.Validation_Results.Is_Ok (R),
      "shutdown request should validate and cancel tree");
   Test_Support.Assert
     (Aion.Shutdown.Is_Requested (Tree),
      "shutdown tree should be requested");
   Test_Support.Assert
     (Aion.Cancel_Token.Is_Cancelled (Aion.Shutdown.Token_Of (Tree)),
      "shutdown token should be cancelled");

   Test_Support.Pass ("shutdown tree converts graceful shutdown into cancellation propagation");
end Test_Runtime_Structured_Shutdown;
