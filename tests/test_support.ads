with Interfaces;

package Test_Support is
   procedure Section (Name : String);
   procedure Assert (Condition : Boolean; Message : String);
   procedure Assert_U64_Equals
     (Expected : Interfaces.Unsigned_64;
      Actual   : Interfaces.Unsigned_64;
      Message  : String);
   procedure Assert_U64_At_Least
     (Minimum : Interfaces.Unsigned_64;
      Actual  : Interfaces.Unsigned_64;
      Message : String);
   procedure Pass (Message : String);
end Test_Support;
