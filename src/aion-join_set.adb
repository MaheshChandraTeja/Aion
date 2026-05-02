with Ada.Real_Time;
with Ada.Strings.Fixed;
with Aion.Errors;


package body Aion.Join_Set is
   use type Aion.Types.Milliseconds;
   use type Interfaces.Unsigned_64;

   function Trim (Value : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both);
   end Trim;

   procedure Clear (Set : in out Join_Set) is
   begin
      for I in Set.Slots'Range loop
         Set.Slots (I) :=
           (Used   => False,
            Joined => False,
            Handle => Aion.Task_Handle.Null_Handle);
      end loop;
      Set.Count := 0;
   end Clear;

   function Add
     (Set    : in out Join_Set;
      Handle : Aion.Task_Handle.Task_Handle)
      return Operation_Results.Result_Type is
   begin
      if not Aion.Task_Handle.Is_Valid (Handle) then
         return Operation_Results.Failure
           (Aion.Errors.Invalid_Argument,
            "cannot add invalid task handle to join set",
            "Aion.Join_Set.Add");
      end if;

      if Set.Count >= Set.Max_Tasks then
         return Operation_Results.Failure
           (Aion.Errors.Capacity_Exceeded,
            "join set capacity exceeded",
            "Aion.Join_Set.Add");
      end if;

      for I in Set.Slots'Range loop
         if not Set.Slots (I).Used then
            Set.Slots (I) :=
              (Used   => True,
               Joined => False,
               Handle => Handle);
            Set.Count := Set.Count + 1;
            return Operation_Results.Success (True);
         end if;
      end loop;

      return Operation_Results.Failure
        (Aion.Errors.Internal_Error,
         "join set had count capacity but no available slot",
         "Aion.Join_Set.Add");
   end Add;

   function Deadline_Passed
     (Started : Ada.Real_Time.Time;
      Timeout : Aion.Types.Milliseconds) return Boolean
   is
      use Ada.Real_Time;
      Timeout_Span : constant Time_Span :=
        Milliseconds (Integer (Timeout));
   begin
      return Timeout > 0 and then Clock - Started >= Timeout_Span;
   end Deadline_Passed;

   function Join_Next
     (Set     : in out Join_Set;
      Token   : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Timeout : Aion.Types.Milliseconds := 0)
      return Handle_Results.Result_Type
   is
      use Ada.Real_Time;
      Started : constant Time := Clock;
   begin
      loop
         if Aion.Cancel_Token.Is_Valid (Token)
           and then Aion.Cancel_Token.Is_Cancelled (Token)
         then
            return Handle_Results.Failure
              (Aion.Errors.Cancelled,
               "join set wait cancelled",
               "Aion.Join_Set.Join_Next");
         end if;

         for I in Set.Slots'Range loop
            if Set.Slots (I).Used
              and then not Set.Slots (I).Joined
              and then Aion.Task_Handle.Is_Done (Set.Slots (I).Handle)
            then
               Set.Slots (I).Joined := True;
               return Handle_Results.Success (Set.Slots (I).Handle);
            end if;
         end loop;

         if Deadline_Passed (Started, Timeout) then
            return Handle_Results.Failure
              (Aion.Errors.Timeout,
               "timed out joining next task",
               "Aion.Join_Set.Join_Next");
         end if;

         delay 0.001;
      end loop;
   end Join_Next;

   function Join_All
     (Set     : in out Join_Set;
      Token   : Aion.Cancel_Token.Cancel_Token :=
        Aion.Cancel_Token.Null_Token;
      Timeout : Aion.Types.Milliseconds := 0)
      return Operation_Results.Result_Type
   is
      use Ada.Real_Time;
      Started : constant Time := Clock;
   begin
      loop
         declare
            Pending : constant Natural := Pending_Of (Set);
         begin
            if Pending = 0 then
               return Operation_Results.Success (True);
            end if;
         end;

         if Aion.Cancel_Token.Is_Valid (Token)
           and then Aion.Cancel_Token.Is_Cancelled (Token)
         then
            return Operation_Results.Failure
              (Aion.Errors.Cancelled,
               "join all cancelled",
               "Aion.Join_Set.Join_All");
         end if;

         if Deadline_Passed (Started, Timeout) then
            return Operation_Results.Failure
              (Aion.Errors.Timeout,
               "timed out joining all tasks",
               "Aion.Join_Set.Join_All");
         end if;

         for I in Set.Slots'Range loop
            if Set.Slots (I).Used
              and then not Set.Slots (I).Joined
              and then Aion.Task_Handle.Is_Done (Set.Slots (I).Handle)
            then
               Set.Slots (I).Joined := True;
            end if;
         end loop;

         delay 0.001;
      end loop;
   end Join_All;

   function Cancel_All
     (Set    : in out Join_Set;
      Reason : String := "join set cancelled")
      return Operation_Results.Result_Type is
   begin
      for I in Set.Slots'Range loop
         if Set.Slots (I).Used
           and then not Aion.Task_Handle.Is_Done (Set.Slots (I).Handle)
         then
            Aion.Task_Handle.Mark_Cancelled (Set.Slots (I).Handle, Reason);
            Set.Slots (I).Joined := True;
         end if;
      end loop;

      return Operation_Results.Success (True);
   end Cancel_All;

   function Count_Of (Set : Join_Set) return Natural is
   begin
      return Set.Count;
   end Count_Of;

   function Pending_Of (Set : Join_Set) return Natural is
      Pending : Natural := 0;
   begin
      for I in Set.Slots'Range loop
         if Set.Slots (I).Used and then not Set.Slots (I).Joined then
            Pending := Pending + 1;
         end if;
      end loop;
      return Pending;
   end Pending_Of;

   function Stats_Of (Set : Join_Set) return Join_Stats is
      Stats : Join_Stats;
   begin
      Stats.Registered := Interfaces.Unsigned_64 (Set.Count);
      for I in Set.Slots'Range loop
         if Set.Slots (I).Used then
            case Aion.Task_Handle.State_Of (Set.Slots (I).Handle) is
               when Aion.Types.Task_Completed =>
                  Stats.Completed := Stats.Completed + 1;
               when Aion.Types.Task_Faulted =>
                  Stats.Failed := Stats.Failed + 1;
               when Aion.Types.Task_Cancelled =>
                  Stats.Cancelled := Stats.Cancelled + 1;
               when others =>
                  if not Set.Slots (I).Joined then
                     Stats.Pending := Stats.Pending + 1;
                  end if;
            end case;
         end if;
      end loop;
      return Stats;
   end Stats_Of;

   function Image (Stats : Join_Stats) return String is
   begin
      return
        "Join_Stats(registered=" & Trim (Interfaces.Unsigned_64'Image (Stats.Registered)) &
        ", completed=" & Trim (Interfaces.Unsigned_64'Image (Stats.Completed)) &
        ", failed=" & Trim (Interfaces.Unsigned_64'Image (Stats.Failed)) &
        ", cancelled=" & Trim (Interfaces.Unsigned_64'Image (Stats.Cancelled)) &
        ", pending=" & Trim (Natural'Image (Stats.Pending)) & ")";
   end Image;

end Aion.Join_Set;
