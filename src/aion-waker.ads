--  Minimal runtime waker primitive used by scheduler-facing components.
--  Later modules can attach this to futures, timers, channels, and reactor
--  registrations without changing the public shape.

with Aion.Types;

package Aion.Waker is

   protected type Wake_Flag is
      procedure Wake;
      procedure Reset;
      function Is_Awake return Boolean;
      function Wake_Count return Natural;
   private
      Awake : Boolean := False;
      Count : Natural := 0;
   end Wake_Flag;

   type Wake_Flag_Access is access all Wake_Flag;

   type Waker is private;

   function Noop return Waker;
   function For_Task
     (Id   : Aion.Types.Task_Id;
      Flag : Wake_Flag_Access) return Waker;

   procedure Wake (Item : Waker);
   function Is_Noop (Item : Waker) return Boolean;
   function Task_Of (Item : Waker) return Aion.Types.Task_Id;

private
   type Waker is record
      Id   : Aion.Types.Task_Id := Aion.Types.No_Task;
      Flag : Wake_Flag_Access := null;
   end record;

end Aion.Waker;
