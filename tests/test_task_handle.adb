with Aion.Errors;
with Aion.Task_Handle;
with Aion.Types;
with Test_Support;

procedure Test_Task_Handle is
   use type Aion.Types.Task_Id;
   use type Aion.Types.Task_State;
   use type Aion.Errors.Error_Code;
   Handle : Aion.Task_Handle.Task_Handle :=
     Aion.Task_Handle.Create (42, "handle-test");
   Failure : constant Aion.Errors.Error :=
     Aion.Errors.Make
       (Aion.Errors.Runtime_Error,
        "boom",
        "Test_Task_Handle");
begin
   Test_Support.Section ("task handle");

   Test_Support.Assert (Aion.Task_Handle.Is_Valid (Handle), "created handle is valid");
   Test_Support.Assert (Aion.Task_Handle.Id_Of (Handle) = 42, "handle preserves id");
   Test_Support.Assert (Aion.Task_Handle.Name_Of (Handle) = "handle-test", "handle preserves name");

   Aion.Task_Handle.Mark_Running (Handle);
   Test_Support.Assert
     (Aion.Task_Handle.State_Of (Handle) = Aion.Types.Task_Running,
      "handle marks running");

   Aion.Task_Handle.Mark_Faulted (Handle, Failure);
   Test_Support.Assert
     (Aion.Task_Handle.State_Of (Handle) = Aion.Types.Task_Faulted,
      "handle marks faulted");
   Test_Support.Assert
     (Aion.Errors.Code_Of (Aion.Task_Handle.Last_Error_Of (Handle)) = Aion.Errors.Runtime_Error,
      "handle stores last error");
   Test_Support.Assert (Aion.Task_Handle.Is_Done (Handle), "faulted task is terminal");

   Test_Support.Pass ("task handle lifecycle works");
end Test_Task_Handle;
