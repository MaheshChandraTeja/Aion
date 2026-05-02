with Aion.Readiness;
with Test_Support;

procedure Test_Readiness is
   R : constant Aion.Readiness.Readiness_Set :=
     Aion.Readiness.Union (Aion.Readiness.Readable, Aion.Readiness.Writable);
begin
   Test_Support.Section ("readiness flags");
   Test_Support.Assert (Aion.Readiness.Any (R), "combined readiness should be non-empty");
   Test_Support.Assert
     (Aion.Readiness.Contains (R, Aion.Readiness.Readable),
      "combined readiness should contain readable");
   Test_Support.Assert
     (Aion.Readiness.Matches (R, Aion.Readiness.Writable),
      "combined readiness should match writable interest");
   Test_Support.Assert
     (not Aion.Readiness.Matches (Aion.Readiness.Readable, Aion.Readiness.Writable),
      "readable should not match write-only interest");
   Test_Support.Assert
     (Aion.Readiness.Any (Aion.Readiness.Intersect (R, Aion.Readiness.Readable)),
      "intersection should keep readable flag");
   Test_Support.Pass (Aion.Readiness.Image (R));
end Test_Readiness;
