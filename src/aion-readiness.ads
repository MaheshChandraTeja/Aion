--  Readiness flags used by the Aion reactor.
--
--  This package is intentionally small and reusable. Networking, file I/O,
--  pipes, process handles, and future platform backends should express their
--  interests and readiness events with this single type instead of inventing
--  private readiness enums in every module.

package Aion.Readiness is
   pragma Preelaborate;

   type Readiness_Set is record
      Readable : Boolean := False;
      Writable : Boolean := False;
      Error    : Boolean := False;
      Hangup   : Boolean := False;
   end record;

   None      : constant Readiness_Set := (others => False);
   Readable  : constant Readiness_Set :=
     (Readable => True, Writable => False, Error => False, Hangup => False);
   Writable  : constant Readiness_Set :=
     (Readable => False, Writable => True, Error => False, Hangup => False);
   Error     : constant Readiness_Set :=
     (Readable => False, Writable => False, Error => True, Hangup => False);
   Hangup    : constant Readiness_Set :=
     (Readable => False, Writable => False, Error => False, Hangup => True);
   Read_Write : constant Readiness_Set :=
     (Readable => True, Writable => True, Error => False, Hangup => False);
   All_Readiness : constant Readiness_Set := (others => True);

   function Any (Item : Readiness_Set) return Boolean;
   function Contains
     (Actual   : Readiness_Set;
      Expected : Readiness_Set) return Boolean;
   function Matches
     (Actual   : Readiness_Set;
      Interest : Readiness_Set) return Boolean;
   function Union
     (Left  : Readiness_Set;
      Right : Readiness_Set) return Readiness_Set;
   function Intersect
     (Left  : Readiness_Set;
      Right : Readiness_Set) return Readiness_Set;
   function Without
     (Left  : Readiness_Set;
      Right : Readiness_Set) return Readiness_Set;
   function Image (Item : Readiness_Set) return String;
end Aion.Readiness;
