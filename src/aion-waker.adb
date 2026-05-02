package body Aion.Waker is
   use type Aion.Types.Task_Id;

   protected body Wake_Flag is
      procedure Wake is
      begin
         Awake := True;
         Count := Count + 1;
      end Wake;

      procedure Reset is
      begin
         Awake := False;
      end Reset;

      function Is_Awake return Boolean is
      begin
         return Awake;
      end Is_Awake;

      function Wake_Count return Natural is
      begin
         return Count;
      end Wake_Count;
   end Wake_Flag;

   function Noop return Waker is
   begin
      return Waker'(Id => Aion.Types.No_Task, Flag => null);
   end Noop;

   function For_Task
     (Id   : Aion.Types.Task_Id;
      Flag : Wake_Flag_Access) return Waker is
   begin
      return Waker'(Id => Id, Flag => Flag);
   end For_Task;

   procedure Wake (Item : Waker) is
   begin
      if Item.Flag /= null then
         Item.Flag.Wake;
      end if;
   end Wake;

   function Is_Noop (Item : Waker) return Boolean is
   begin
      return Item.Flag = null or else Item.Id = Aion.Types.No_Task;
   end Is_Noop;

   function Task_Of (Item : Waker) return Aion.Types.Task_Id is
   begin
      return Item.Id;
   end Task_Of;

end Aion.Waker;
