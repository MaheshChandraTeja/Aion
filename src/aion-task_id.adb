with Ada.Strings.Fixed;

package body Aion.Task_Id is
   use type Aion.Types.Task_Id;

   protected body Generator is
      procedure Reset (Start : Aion.Types.Task_Id := 1) is
      begin
         if Start = Aion.Types.No_Task then
            Current := 1;
         else
            Current := Start;
         end if;
      end Reset;

      procedure Next (Id : out Aion.Types.Task_Id) is
      begin
         Id := Current;

         if Current = Aion.Types.Task_Id'Last then
            Current := 1;
         else
            Current := Current + 1;
         end if;
      end Next;

      function Peek return Aion.Types.Task_Id is
      begin
         return Current;
      end Peek;
   end Generator;

   function Is_Valid (Id : Aion.Types.Task_Id) return Boolean is
   begin
      return Id /= Aion.Types.No_Task;
   end Is_Valid;

   function Image (Id : Aion.Types.Task_Id) return String is
   begin
      return Ada.Strings.Fixed.Trim (Aion.Types.Task_Id'Image (Id), Ada.Strings.Both);
   end Image;

end Aion.Task_Id;
