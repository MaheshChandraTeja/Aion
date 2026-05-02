with Aion.Errors;
with Aion.Types;

package body Aion.Sync.Once is

   package body Generic_Once is
      use type Interfaces.Unsigned_64;
      use type Aion.Types.Task_Id;

      protected body Once_State is
         procedure Set_Value
           (Value    : in Value_Type;
            Accepted : out Boolean) is
         begin
            if Set_Flag then
               Failures := Failures + 1;
               Accepted := False;
            else
               Stored_Value := Value;
               Set_Flag := True;
               Releases := Releases + 1;
               Accepted := True;
            end if;
         end Set_Value;

         procedure Request
           (Future   : in Value_Futures.Future_Handle;
            Immediate : out Boolean;
            Value     : out Value_Type;
            Accepted  : out Boolean) is
         begin
            if Set_Flag then
               Value := Stored_Value;
               Immediate := True;
               Accepted := True;
               Acquisitions := Acquisitions + 1;
            elsif Count >= Max_Waiters then
               Immediate := False;
               Accepted := False;
               Failures := Failures + 1;
            else
               Queue (Tail) := Future;
               if Tail = Max_Waiters then Tail := 1; else Tail := Tail + 1; end if;
               Count := Count + 1;
               Immediate := False;
               Accepted := True;
            end if;
         end Request;

         procedure Pop_Waiter
           (Future : out Value_Futures.Future_Handle;
            Found  : out Boolean) is
         begin
            if Count = 0 then
               Future := Value_Futures.Null_Future;
               Found := False;
            else
               Future := Queue (Head);
               Queue (Head) := Value_Futures.Null_Future;
               if Head = Max_Waiters then Head := 1; else Head := Head + 1; end if;
               Count := Count - 1;
               Wakeups := Wakeups + 1;
               Found := True;
            end if;
         end Pop_Waiter;

         procedure Cancel
           (Future   : in Value_Futures.Future_Handle;
            Accepted : out Boolean) is
            Cursor   : Positive := Head;
            Found_At : Natural := 0;
         begin
            Accepted := False;
            for Offset in 1 .. Count loop
               if Value_Futures.Id_Of (Queue (Cursor)) = Value_Futures.Id_Of (Future) then
                  Found_At := Offset; exit;
               end if;
               if Cursor = Max_Waiters then Cursor := 1; else Cursor := Cursor + 1; end if;
            end loop;

            if Found_At = 0 then
               Failures := Failures + 1; return;
            end if;

            for Shift in Found_At .. Count - 1 loop
               declare
                  To_Index : Positive := Head;
                  From_Index : Positive;
               begin
                  for I in 1 .. Shift - 1 loop
                     if To_Index = Max_Waiters then To_Index := 1; else To_Index := To_Index + 1; end if;
                  end loop;
                  From_Index := To_Index;
                  if From_Index = Max_Waiters then From_Index := 1; else From_Index := From_Index + 1; end if;
                  Queue (To_Index) := Queue (From_Index);
               end;
            end loop;

            if Tail = 1 then Tail := Max_Waiters; else Tail := Tail - 1; end if;
            Queue (Tail) := Value_Futures.Null_Future;
            Count := Count - 1;
            Cancellations := Cancellations + 1;
            Accepted := True;
         end Cancel;

         function Has_Value return Boolean is
         begin
            return Set_Flag;
         end Has_Value;

         function Stored return Value_Type is
         begin
            return Stored_Value;
         end Stored;

         function Waiters return Natural is
         begin
            return Count;
         end Waiters;

         function Snapshot return Aion.Sync.Primitive_Stats is
         begin
            return
              (Waiters       => Count,
               Wakeups       => Wakeups,
               Acquisitions  => Acquisitions,
               Releases      => Releases,
               Cancellations => Cancellations,
               Failures      => Failures);
         end Snapshot;
      end Once_State;

      function Is_Set (Cell : Once_Cell) return Boolean is
      begin
         return Cell.State.Has_Value;
      end Is_Set;

      function Get (Cell : Once_Cell) return Value_Results.Result_Type is
      begin
         if Cell.State.Has_Value then
            return Value_Results.Success (Cell.State.Stored);
         end if;
         return Value_Results.Failure
           (Aion.Errors.Invalid_State,
            "once cell is not initialized", "Aion.Sync.Once.Get");
      end Get;

      function Get_Or_Wait
        (Cell    : in out Once_Cell;
         Runtime : access Aion.Runtime.Runtime_Handle := null;
         Name    : String := "once.wait") return Value_Futures.Future_Handle is
         pragma Unreferenced (Runtime);
         Future    : constant Value_Futures.Future_Handle := Value_Futures.Create (Name => Name);
         Immediate : Boolean;
         Accepted  : Boolean;
         Value     : Value_Type;
         Ignored   : Value_Futures.Operation_Results.Result_Type;
      begin
         Cell.State.Request (Future, Immediate, Value, Accepted);
         if not Accepted then
            Ignored := Value_Futures.Complete_Failure
              (Future, Aion.Errors.Capacity_Exceeded,
               "once waiter queue is full", "Aion.Sync.Once.Get_Or_Wait");
         elsif Immediate then
            Ignored := Value_Futures.Complete_Success (Future, Value);
         end if;
         return Future;
      end Get_Or_Wait;

      function Set
        (Cell  : in out Once_Cell;
         Value : Value_Type) return Aion.Sync.Boolean_Results.Result_Type is
         Accepted : Boolean;
         Future   : Value_Futures.Future_Handle;
         Found    : Boolean;
         Ignored  : Value_Futures.Operation_Results.Result_Type;
      begin
         Cell.State.Set_Value (Value, Accepted);
         if not Accepted then
            return Aion.Sync.Boolean_Results.Failure
              (Aion.Errors.Invalid_State,
               "once cell was already initialized", "Aion.Sync.Once.Set");
         end if;

         loop
            Cell.State.Pop_Waiter (Future, Found);
            exit when not Found;
            Ignored := Value_Futures.Complete_Success (Future, Value);
         end loop;

         return Aion.Sync.Boolean_Results.Success (True);
      end Set;

      function Cancel_Waiter
        (Cell   : in out Once_Cell;
         Future : Value_Futures.Future_Handle;
         Reason : String := "once waiter cancelled")
         return Aion.Sync.Boolean_Results.Result_Type is
         Accepted : Boolean;
         Ignored  : Value_Futures.Operation_Results.Result_Type;
      begin
         Cell.State.Cancel (Future, Accepted);
         if Accepted then
            Ignored := Value_Futures.Complete_Cancelled (Future, Reason);
            return Aion.Sync.Boolean_Results.Success (True);
         end if;
         return Aion.Sync.Boolean_Results.Failure
           (Aion.Errors.Invalid_State,
            "future is not queued on this once cell", "Aion.Sync.Once.Cancel_Waiter");
      end Cancel_Waiter;

      function Waiter_Count_Of (Cell : Once_Cell) return Natural is
      begin
         return Cell.State.Waiters;
      end Waiter_Count_Of;

      function Stats_Of (Cell : Once_Cell) return Aion.Sync.Primitive_Stats is
      begin
         return Cell.State.Snapshot;
      end Stats_Of;

   end Generic_Once;

end Aion.Sync.Once;
