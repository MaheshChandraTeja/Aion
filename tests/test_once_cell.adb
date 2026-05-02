with Aion.Sync.Once;
with Test_Support;

procedure Test_Once_Cell is
   package Integer_Once is new Aion.Sync.Once.Generic_Once (Integer);

   Cell : Integer_Once.Once_Cell (Max_Waiters => 16);
   F    : Integer_Once.Value_Futures.Future_Handle;
   R    : Integer_Once.Value_Futures.Value_Results.Result_Type;
   GetR : Integer_Once.Value_Results.Result_Type;
   Done : Aion.Sync.Boolean_Results.Result_Type;
begin
   Test_Support.Section ("Aion.Sync.Once");

   GetR := Integer_Once.Get (Cell);
   Test_Support.Assert
     (Integer_Once.Value_Results.Is_Err (GetR),
      "empty once cell get should fail");

   F := Integer_Once.Get_Or_Wait (Cell);
   Test_Support.Assert
     (Integer_Once.Value_Futures.Is_Pending (F),
      "get_or_wait should wait before set");

   Done := Integer_Once.Set (Cell, 42);
   Test_Support.Assert (Aion.Sync.Boolean_Results.Is_Ok (Done), "first set should pass");

   R := Integer_Once.Value_Futures.Await (F);
   Test_Support.Assert
     (Integer_Once.Value_Futures.Value_Results.Is_Ok (R),
      "waiter should receive once value");
   Test_Support.Assert
     (Integer_Once.Value_Futures.Value_Results.Value (R) = 42,
      "once value should match");

   Done := Integer_Once.Set (Cell, 99);
   Test_Support.Assert
     (Aion.Sync.Boolean_Results.Is_Err (Done),
      "second set should fail");

   Test_Support.Pass ("once cell initializes exactly once");
end Test_Once_Cell;
