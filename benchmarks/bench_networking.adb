with Ada.Text_IO;
with Aion.Net;

procedure Bench_Networking is
   Iterations : constant Positive := 100_000;
   Payload    : Aion.Net.Net_Buffer;
begin
   Ada.Text_IO.Put_Line ("Aion networking buffer benchmark");
   for I in 1 .. Iterations loop
      Payload := Aion.Net.From_String ("benchmark-payload");
      if Aion.Net.Is_Empty (Payload) then
         raise Program_Error with "payload should not be empty";
      end if;
   end loop;
   Ada.Text_IO.Put_Line ("completed" & Positive'Image (Iterations) & " buffer conversions");
end Bench_Networking;
