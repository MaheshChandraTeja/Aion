with Aion;
with Test_Support;

procedure Test_Core_Foundation is
begin
   Test_Support.Section ("core foundation");

   Test_Support.Assert (Aion.Name = "Aion", "library name should be Aion");
   Test_Support.Assert
     (Aion.Description'Length > 0,
      "description should not be empty");

   Aion.Finalize;
   Test_Support.Assert
     (not Aion.Is_Initialized,
      "runtime should start as not initialized after finalize");

   Aion.Initialize;
   Test_Support.Assert
     (Aion.Is_Initialized,
      "initialize should set initialized state");

   Aion.Finalize;
   Test_Support.Assert
     (not Aion.Is_Initialized,
      "finalize should clear initialized state");

   Test_Support.Pass ("core foundation behaves correctly");
end Test_Core_Foundation;
