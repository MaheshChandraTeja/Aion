--  Stable reactor registration token.
--
--  A token identifies a registered I/O resource inside one reactor service.
--  It is deliberately independent from Task_Id so future modules can reuse
--  tokens for sockets, pipes, files, and synthetic readiness sources.

with Interfaces;

package Aion.IO_Token is
   pragma Preelaborate;

   type IO_Token is new Interfaces.Unsigned_64;
   No_Token : constant IO_Token := 0;

   protected type Generator is
      procedure Next (Token : out IO_Token);
      function Current return IO_Token;
   private
      Value : IO_Token := 1;
   end Generator;

   type Generator_Access is access all Generator;

   function Is_Valid (Token : IO_Token) return Boolean;
   function Image (Token : IO_Token) return String;
end Aion.IO_Token;
