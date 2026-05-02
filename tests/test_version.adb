with Aion.Version;
with Test_Support;

procedure Test_Version is
begin
   Test_Support.Section ("version");

   Test_Support.Assert
     (Aion.Version.Semver = "0.1.0-module1",
      "semver should be stable");

   Test_Support.Assert
     (Aion.Version.Full = Aion.Version.Semver,
      "full version should equal semver when build metadata is empty");

   Test_Support.Pass ("version metadata behaves correctly");
end Test_Version;
