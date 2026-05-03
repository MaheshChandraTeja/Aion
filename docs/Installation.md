# Aion Installation

This guide shows how to install Aion for use from another Ada project. It includes both supported paths:

- Alire dependency: `alr with aion`
- Manual GitHub pull: clone the repository and pin or reference it locally

---

## 1. Prerequisites

Install:

```text
Alire
GNAT
GPRbuild
Git
PowerShell or another terminal
```

Verify the toolchain:

```powershell
alr --version
alr toolchain --select
alr exec -- gnat --version
alr exec -- gprbuild --version
```

If `gprbuild` is not available globally but works through `alr exec -- gprbuild`, that is fine. Alire manages toolchain paths for you.

---

## 2. Option A: Install Through Alire

Use this when Aion is available from the Alire index.

Create or open your Ada application:

```powershell
alr init --bin my_app
cd my_app
```

Add Aion:

```powershell
alr with aion
```

Build:

```powershell
alr build
```

This updates your `alire.toml` with an Aion dependency and lets Alire resolve the crate.

---

## 3. Option B: Manual GitHub Pull With Alire Pin

Use this when you want to depend on a local checkout from GitHub.

Clone Aion:

```powershell
git clone https://github.com/MaheshChandraTeja/Aion.git C:\src\Aion
```

Create or open your application:

```powershell
alr init --bin my_app
cd my_app
```

Pin your application to the local checkout:

```powershell
alr with aion --use C:\src\Aion
```

Build:

```powershell
alr build
```

Use this same command when developing against a local Aion branch:

```powershell
alr with aion --use <path-to-your-aion-checkout>
```

---

## 4. Option C: Manual GitHub Pull Without Alire

Use this when your application is a plain GPRbuild project.

Clone Aion:

```powershell
git clone https://github.com/MaheshChandraTeja/Aion.git C:\src\Aion
```

Reference Aion from your application project file:

```ada
with "C:\src\Aion\aion.gpr";

project My_App is
   for Source_Dirs use ("src");
   for Object_Dir use "obj";
   for Exec_Dir use "bin";
   for Main use ("main.adb");
end My_App;
```

Build your application:

```powershell
gprbuild -P my_app.gpr
```

If you still want to use Alire only for the compiler environment:

```powershell
alr exec -- gprbuild -P my_app.gpr
```

---

## 5. Minimal Consumer Program

Replace your generated main file with:

```ada
with Ada.Text_IO;
with Aion;
with Aion.Config;
with Aion.Errors;
with Aion.Runtime;

procedure My_App is
   Runtime : Aion.Runtime.Runtime_Handle :=
     Aion.Runtime.Create (Aion.Config.Default);

   Started  : Aion.Runtime.Operation_Results.Result_Type;
   Shutdown : Aion.Runtime.Operation_Results.Result_Type;
begin
   Aion.Initialize;

   Ada.Text_IO.Put_Line ("Using " & Aion.Name);
   Ada.Text_IO.Put_Line (Aion.Description);

   Started := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line
        ("Runtime start failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Started)));
      return;
   end if;

   Ada.Text_IO.Put_Line ("Aion runtime started.");

   Shutdown := Aion.Runtime.Shutdown (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Shutdown) then
      Ada.Text_IO.Put_Line
        ("Runtime shutdown failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Shutdown)));
   end if;
end My_App;
```

Build and run:

```powershell
alr build
alr run
```

Expected output includes:

```text
Using Aion
Aion runtime started.
```

---

## 6. Build Aion From Its Source Checkout

If you cloned Aion and want to verify the library itself:

```powershell
cd C:\src\Aion
alr exec -- gprbuild -P aion.gpr
```

Build examples:

```powershell
alr exec -- gprbuild -P aion_examples.gpr
```

Build tests:

```powershell
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
```

Build benchmarks:

```powershell
alr exec -- gprbuild -P aion_benchmarks.gpr
```

---

## 7. Recommended Consumer Layout

```text
my_app/
├── alire.toml
├── my_app.gpr
└── src/
    ├── my_app.adb
    ├── app_jobs.ads
    └── app_jobs.adb
```

Place runtime job procedures in package-level units such as `app_jobs.ads` and `app_jobs.adb` when passing them to Aion with `'Access`.

---

## 8. Troubleshooting

### `alr with aion` cannot find the crate

Aion may not be available in your configured Alire index yet. Use the local checkout form:

```powershell
alr with aion --use C:\src\Aion
```

### Consumer project cannot find Aion after a manual pull

Confirm the local path points to the repository root containing `alire.toml` and `aion.gpr`:

```powershell
Get-ChildItem C:\src\Aion
```

Then re-run:

```powershell
alr with aion --use C:\src\Aion
alr build
```

### `gprbuild` is not recognized

Use Alire's toolchain environment:

```powershell
alr exec -- gprbuild -P aion.gpr
```

### Ada cannot find a package

Make sure the top of your Ada unit has the needed `with` clauses:

```ada
with Aion;
with Aion.Runtime;
with Aion.Config;
```

Ada does not use `import Aion`.

### Runtime job access errors

Move the job procedure into a library-level or package-level unit before passing it with `'Access`.
