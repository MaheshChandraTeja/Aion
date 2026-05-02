package body Aion.Readiness is

   function Any (Item : Readiness_Set) return Boolean is
   begin
      return Item.Readable or else Item.Writable or else Item.Error or else Item.Hangup;
   end Any;

   function Contains
     (Actual   : Readiness_Set;
      Expected : Readiness_Set) return Boolean is
   begin
      return
        (not Expected.Readable or else Actual.Readable) and then
        (not Expected.Writable or else Actual.Writable) and then
        (not Expected.Error or else Actual.Error) and then
        (not Expected.Hangup or else Actual.Hangup);
   end Contains;

   function Matches
     (Actual   : Readiness_Set;
      Interest : Readiness_Set) return Boolean is
   begin
      return
        (Actual.Readable and then Interest.Readable) or else
        (Actual.Writable and then Interest.Writable) or else
        (Actual.Error and then Interest.Error) or else
        (Actual.Hangup and then Interest.Hangup);
   end Matches;

   function Union
     (Left  : Readiness_Set;
      Right : Readiness_Set) return Readiness_Set is
   begin
      return
        (Readable => Left.Readable or else Right.Readable,
         Writable => Left.Writable or else Right.Writable,
         Error    => Left.Error or else Right.Error,
         Hangup   => Left.Hangup or else Right.Hangup);
   end Union;

   function Intersect
     (Left  : Readiness_Set;
      Right : Readiness_Set) return Readiness_Set is
   begin
      return
        (Readable => Left.Readable and then Right.Readable,
         Writable => Left.Writable and then Right.Writable,
         Error    => Left.Error and then Right.Error,
         Hangup   => Left.Hangup and then Right.Hangup);
   end Intersect;

   function Without
     (Left  : Readiness_Set;
      Right : Readiness_Set) return Readiness_Set is
   begin
      return
        (Readable => Left.Readable and then not Right.Readable,
         Writable => Left.Writable and then not Right.Writable,
         Error    => Left.Error and then not Right.Error,
         Hangup   => Left.Hangup and then not Right.Hangup);
   end Without;

   function Image (Item : Readiness_Set) return String is
      Result : constant String :=
        "Readiness(read=" & Boolean'Image (Item.Readable) &
        ", write=" & Boolean'Image (Item.Writable) &
        ", error=" & Boolean'Image (Item.Error) &
        ", hangup=" & Boolean'Image (Item.Hangup) & ")";
   begin
      return Result;
   end Image;

end Aion.Readiness;
