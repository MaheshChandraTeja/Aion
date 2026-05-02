# Aion Installation

This guide explains how to install, build, package, and consume Aion as an Ada library.

Aion is designed to be used through **Alire** and **GPRbuild**. Alire manages Ada dependencies and toolchains. GPRbuild compiles Ada projects through `.gpr` project files. Together, they form the least painful path, which in Ada tooling terms is practically a spa day.

---

## 1. Prerequisites

You need:

```text
Alire
GNAT
GPRbuild
PowerShell or terminal
Git
```

Recommended platform for current development:

```text
Windows 10/11
Alire-managed GNAT native compiler
Alire-managed GPRbuild
```

Aion should also be structurally portable to Linux and macOS, especially for core runtime, futures, timers, channels, and cancellation. Native networking backend maturity depends on the platform backend implementation.

---

## 2. Install Alire

Download and install Alire from the official Alire distribution for your platform.

After installation, verify:

```powershell
alr --version
```

If that works, select/install the Ada toolchain:

```powershell
alr toolchain --select
```

Choose:

```text
gnat_native
gprbuild
```

Then verify through Alire:

```powershell
alr exec -- gnat --version
alr exec -- gprbuild --version
```

If plain `gprbuild` does not work but `alr exec -- gprbuild` works, that is normal. Alire manages its own toolchain paths. Windows PATH is not psychic, despite all evidence that software expects it to be.

---

## 3. Clone or Place Aion Locally

Example project location:

```powershell
F:\Projects-INT\Aion
```

If using Git:

```powershell
cd F:\Projects-INT
git clone https://github.com/<your-user-or-org>/Aion.git
cd Aion
```

If using a local folder, just open PowerShell in the Aion root.

You should see:

```text
aion.gpr
aion_tests.gpr
aion_examples.gpr
aion_benchmarks.gpr
alire.toml
src/
tests/
examples/
benchmarks/
docs/
```

---

## 4. Build the Aion Library

From the Aion root:

```powershell
alr exec -- gprbuild -P aion.gpr
```

Expected output includes compilation and a static library build, usually something like:

```text
Build Libraries
[gprlib]       aion.lexch
[archive]      libaion.a
[index]        libaion.a
```

That means the library project builds successfully.

---

## 5. Build Examples

```powershell
alr exec -- gprbuild -P aion_examples.gpr
```

Run a simple example:

```powershell
.\bin\aion_module1_app.exe
```

Run the observability example:

```powershell
.\bin\observability_demo.exe
```

If the executable is not in `bin`, find it:

```powershell
Get-ChildItem -Recurse -Filter "observability_demo.exe"
```

---

## 6. Build Tests

```powershell
alr exec -- gprbuild -P aion_tests.gpr
```

Run the test runner:

```powershell
.\bin\test_runner.exe
```

Clean rebuild:

```powershell
Remove-Item .\obj -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\bin -Recurse -Force -ErrorAction SilentlyContinue

alr exec -- gprbuild -P aion.gpr
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
```

---

## 7. Build Benchmarks

```powershell
alr exec -- gprbuild -P aion_benchmarks.gpr
```

Run benchmark binaries:

```powershell
.\bin\bench_scheduler.exe
.\bin\bench_spawn.exe
.\bin\bench_timers.exe
.\bin\bench_channels.exe
.\bin\bench_cancellation.exe
.\bin\bench_reactor.exe
.\bin\bench_tcp_echo.exe
```

Example benchmark output:

```text
scheduler_stats_snapshot: operations=100000, elapsed_ms=22, ops_per_sec=4.54545454545455E+06
queue_capacity= 16384
```

Treat benchmark results as local machine indicators, not universal truth tablets carried down from Mount Compiler.

---

## 8. Use Aion in Another Ada Project

Create a consumer project:

```powershell
cd C:\Users\MarshFang\Downloads
alr init --bin aion_consumer
cd aion_consumer
```

Add Aion as a local dependency:

```powershell
alr with aion --use F:\Projects-INT\Aion
```

This tells Alire to use your local Aion library.

Check the generated/updated manifest:

```powershell
Get-Content .\alire.toml
```

You should see a dependency/pin reference to Aion.

---

## 9. Minimal Consumer Code

Replace `src/aion_consumer.adb` with:

```ada
with Ada.Text_IO;
with Aion;
with Aion.Config;
with Aion.Runtime;
with Aion.Errors;

procedure Aion_Consumer is
   Config  : constant Aion.Config.Runtime_Config := Aion.Config.Default;
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create (Config);

   Shutdown_Result : Aion.Runtime.Operation_Results.Result_Type;
begin
   Aion.Initialize;

   Ada.Text_IO.Put_Line ("Using " & Aion.Name);
   Ada.Text_IO.Put_Line (Aion.Description);
   Ada.Text_IO.Put_Line ("Aion runtime created successfully.");

   Shutdown_Result := Aion.Runtime.Shutdown (Runtime);

   if Aion.Runtime.Operation_Results.Is_Ok (Shutdown_Result) then
      Ada.Text_IO.Put_Line ("Runtime shut down successfully.");
   else
      Ada.Text_IO.Put_Line
        ("Runtime shutdown failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Shutdown_Result)));
   end if;
end Aion_Consumer;
```

Build:

```powershell
alr build
```

Run:

```powershell
alr run
```

Expected output:

```text
Using Aion
Aion is a structured asynchronous runtime and scheduler foundation for Ada.
Aion runtime created successfully.
Runtime shut down successfully.
```

That confirms Aion is usable as a library from a separate project.

---

## 10. Ada Import Syntax

Ada does not use:

```ada
import Aion;
```

Ada uses:

```ada
with Aion;
```

For child packages:

```ada
with Aion.Runtime;
with Aion.Config;
with Aion.Future;
with Aion.Channel.Bounded;
```

Then call with qualified names:

```ada
Aion.Runtime.Create
Aion.Config.Default
```

This is more explicit than Python-style imports. Slightly more typing, far fewer mystery names. A reasonable trade, despite humanity’s tragic allergy to verbosity.

---

## 11. Package Aion as a Library

Aion’s library project file should expose a library build.

Example `aion.gpr` shape:

```ada
library project Aion is

   for Source_Dirs use ("src");
   for Object_Dir use "obj/lib";
   for Library_Dir use "lib";
   for Library_Name use "aion";
   for Library_Kind use "static";

   package Compiler is
      for Default_Switches ("Ada") use
        ("-gnat2022", "-gnatwa", "-O2");
   end Compiler;

end Aion;
```

Build:

```powershell
alr exec -- gprbuild -P aion.gpr
```

Expected artifact:

```text
lib/libaion.a
```

---

## 12. Recommended `alire.toml`

```toml
name = "aion"
description = "Structured asynchronous runtime for Ada"
version = "0.1.0"
licenses = "MIT"
authors = ["Kairais Tech"]
maintainers = ["Kairais Tech"]
maintainers-logins = ["MaheshChandraTeja"]
website = "https://www.kairais.com"
tags = ["ada", "async", "runtime", "scheduler", "networking", "concurrency"]

project-files = ["aion.gpr"]

[build-switches]
"*".ada_version = "Ada2022"
```

Keep the manifest clean. Do not turn it into a motivational poster.

---

## 13. Publish Later as an Alire Crate

When Aion is ready for external use:

```powershell
git add .
git commit -m "Release Aion v0.1.0"
git tag v0.1.0
git push origin main
git push origin v0.1.0
```

Then:

```powershell
alr publish
```

Once published, consumers can use:

```powershell
alr with aion
```

instead of:

```powershell
alr with aion --use F:\Projects-INT\Aion
```

---

## 14. Common Installation Problems

### `gprbuild` is not recognized

Use:

```powershell
alr exec -- gprbuild -P aion.gpr
```

Alire may know where `gprbuild` is even when your global PATH does not.

### `gnat1` missing

Your GNAT installation is incomplete or not correctly selected. Run:

```powershell
alr toolchain --select
```

Then retry:

```powershell
alr exec -- gnat --version
alr exec -- gprbuild --version
```

### Consumer project cannot find Aion

Re-add the local dependency:

```powershell
alr with aion --use F:\Projects-INT\Aion
```

Then:

```powershell
alr build
```

### Filename warning in consumer project

If the file is:

```text
aion_consumer.adb
```

then the procedure should be:

```ada
procedure Aion_Consumer is
```

GNAT expects Ada unit names and filenames to match.

### Cannot ignore function result

If a function returns a result, store it:

```ada
Shutdown_Result := Aion.Runtime.Shutdown (Runtime);
```

Ada does not let you throw return values into the void. Rude? Maybe. Useful? Definitely.

---

## 15. Recommended Developer Commands

From the Aion root:

```powershell
alr exec -- gprbuild -P aion.gpr
alr exec -- gprbuild -P aion_examples.gpr
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
alr exec -- gprbuild -P aion_benchmarks.gpr
```

Clean all generated output:

```powershell
Remove-Item .\obj -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\bin -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\lib -Recurse -Force -ErrorAction SilentlyContinue
```

---

## 16. Installation Status Checklist

Aion is installed correctly when all of these pass:

```powershell
alr exec -- gprbuild -P aion.gpr
alr exec -- gprbuild -P aion_examples.gpr
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
alr exec -- gprbuild -P aion_benchmarks.gpr
```

Aion is usable as a library when a separate consumer project can run:

```powershell
alr with aion --use F:\Projects-INT\Aion
alr build
alr run
```

and print:

```text
Using Aion
Aion runtime created successfully.
Runtime shut down successfully.
```
