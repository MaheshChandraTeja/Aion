with Aion.IO_Token;
with Test_Support;

procedure Test_IO_Token is
   use type Aion.IO_Token.IO_Token;
   Gen : Aion.IO_Token.Generator;
   A   : Aion.IO_Token.IO_Token;
   B   : Aion.IO_Token.IO_Token;
begin
   Test_Support.Section ("io token generator");
   Gen.Next (A);
   Gen.Next (B);

   Test_Support.Assert (Aion.IO_Token.Is_Valid (A), "first token should be valid");
   Test_Support.Assert (Aion.IO_Token.Is_Valid (B), "second token should be valid");
   Test_Support.Assert (A /= B, "token generator should produce distinct consecutive values");
   Test_Support.Assert
     (not Aion.IO_Token.Is_Valid (Aion.IO_Token.No_Token),
      "no token should be invalid");
   Test_Support.Pass (Aion.IO_Token.Image (A));
end Test_IO_Token;
