--  Cooperative yield helpers for runtime jobs.
--  Ada already has task scheduling; this package gives Aion users a stable
--  library-level place to express cooperative yielding.

package Aion.Yield is
   procedure Now;
   procedure Times (Count : Positive);
end Aion.Yield;
