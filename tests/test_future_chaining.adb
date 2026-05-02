with Aion.Block_On;
with Aion.Config;
with Aion.Runtime;
with Test_Future_Jobs;
with Test_Support;

procedure Test_Future_Chaining is
   package Int_Block_On is new Aion.Block_On.Generic_Block_On
     (Test_Future_Jobs.Int_Futures);

   Runtime : Aion.Runtime.Runtime_Handle :=
     Aion.Runtime.Create
       (Aion.Config.With_Workers
          (Aion.Config.With_Max_Queue_Depth
             (Aion.Config.With_Name (Aion.Config.Default, "future-runtime-test"),
              16),
           2));

   Start_Result : Aion.Runtime.Operation_Results.Result_Type;
   Spawn_Result : Aion.Runtime.Spawn_Results.Result_Type;
   Stop_Result  : Aion.Runtime.Operation_Results.Result_Type;
   Await_Result : Test_Future_Jobs.Int_Futures.Value_Results.Result_Type;
begin
   Test_Support.Section ("future chaining and runtime propagation");

   Test_Future_Jobs.Reset;

   Start_Result := Aion.Runtime.Start (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Start_Result),
      "runtime starts");

   Spawn_Result := Aion.Runtime.Spawn
     (Runtime,
      "complete-future-from-worker",
      Test_Future_Jobs.Complete_42'Access);
   Test_Support.Assert
     (Aion.Runtime.Spawn_Results.Is_Ok (Spawn_Result),
      "runtime spawns future completion job");

   Await_Result := Int_Block_On.Run_Timeout (Test_Future_Jobs.Future, 2_000);
   Test_Support.Assert
     (Test_Future_Jobs.Int_Futures.Value_Results.Is_Ok (Await_Result),
      "sync code awaits runtime-completed future");
   Test_Support.Assert
     (Test_Future_Jobs.Int_Futures.Value_Results.Value (Await_Result) = 42,
      "runtime job propagated future value");

   Stop_Result := Aion.Runtime.Shutdown (Runtime);
   Test_Support.Assert
     (Aion.Runtime.Operation_Results.Is_Ok (Stop_Result),
      "runtime shuts down after future propagation");

   Test_Support.Pass ("future result propagation through runtime workers works");
end Test_Future_Chaining;
