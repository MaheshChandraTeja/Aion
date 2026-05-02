--  Join set for waiting on a group of spawned runtime task handles.

with Interfaces;
with Aion.Cancel_Token;
with Aion.Result;
with Aion.Task_Handle;
with Aion.Types;

package Aion.Join_Set is

   type Join_Stats is record
      Registered : Interfaces.Unsigned_64 := 0;
      Completed  : Interfaces.Unsigned_64 := 0;
      Failed     : Interfaces.Unsigned_64 := 0;
      Cancelled  : Interfaces.Unsigned_64 := 0;
      Pending    : Natural := 0;
   end record;

   type Join_Set (Max_Tasks : Positive) is limited private;

   package Operation_Results is new Aion.Result.Generic_Result (Boolean);
   package Handle_Results is new Aion.Result.Generic_Result
     (Aion.Task_Handle.Task_Handle);

   procedure Clear (Set : in out Join_Set);

   function Add
     (Set    : in out Join_Set;
      Handle : Aion.Task_Handle.Task_Handle)
      return Operation_Results.Result_Type;

   function Join_Next
     (Set     : in out Join_Set;
      Token   : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Timeout : Aion.Types.Milliseconds := 0)
      return Handle_Results.Result_Type;

   function Join_All
     (Set     : in out Join_Set;
      Token   : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Timeout : Aion.Types.Milliseconds := 0)
      return Operation_Results.Result_Type;

   function Cancel_All
     (Set    : in out Join_Set;
      Reason : String := "join set cancelled")
      return Operation_Results.Result_Type;

   function Count_Of (Set : Join_Set) return Natural;
   function Pending_Of (Set : Join_Set) return Natural;
   function Stats_Of (Set : Join_Set) return Join_Stats;

   function Image (Stats : Join_Stats) return String;

private
   type Handle_Slot is record
      Used    : Boolean := False;
      Joined  : Boolean := False;
      Handle  : Aion.Task_Handle.Task_Handle :=
        Aion.Task_Handle.Null_Handle;
   end record;

   type Handle_Array is array (Positive range <>) of Handle_Slot;

   type Join_Set (Max_Tasks : Positive) is limited record
      Slots : Handle_Array (1 .. Max_Tasks);
      Count : Natural := 0;
   end record;

end Aion.Join_Set;
