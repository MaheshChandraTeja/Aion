# Aion Usage Guide

This guide is for developers who want to use Aion as a library in their own Ada project.

If you are working inside the Aion repository itself, use the build and test commands in `Installation.md`. This page assumes you are writing a separate application that depends on Aion.

---

## 1. Add Aion to Your Project

### Alire crate

If Aion is available from the Alire index, add it from your application root:

```powershell
alr with aion
```

Then build your application:

```powershell
alr build
```

### Local GitHub checkout

If you pulled Aion manually from GitHub, pin your application to that local checkout:

```powershell
git clone https://github.com/MaheshChandraTeja/Aion.git C:\src\Aion

cd C:\src\my_app
alr with aion --use C:\src\Aion
alr build
```

Use the real path where you cloned Aion.

### Manual GPRbuild project

If your application does not use Alire, reference Aion from your `.gpr` project file:

```ada
with "C:\src\Aion\aion.gpr";

project My_App is
   for Source_Dirs use ("src");
   for Object_Dir use "obj";
   for Exec_Dir use "bin";
   for Main use ("main.adb");
end My_App;
```

Build with:

```powershell
gprbuild -P my_app.gpr
```

If `gprbuild` is only available through Alire, use:

```powershell
alr exec -- gprbuild -P my_app.gpr
```

---

## 2. Import Aion Packages

Ada uses `with`, not `import`:

```ada
with Aion;
with Aion.Config;
with Aion.Runtime;
```

Call Aion APIs through qualified package names:

```ada
Aion.Initialize;
Aion.Config.Default;
Aion.Runtime.Create;
```

Qualified names are recommended for application code because they keep runtime, channel, cancellation, and networking calls easy to audit.

---

## 3. Minimal Application

```ada
with Ada.Text_IO;
with Aion;
with Aion.Config;
with Aion.Errors;
with Aion.Runtime;

procedure Main is
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
end Main;
```

Build and run from your application root:

```powershell
alr build
alr run
```

---

## 4. Runtime Configuration

Use `Aion.Config.Runtime_Config` to configure the runtime before creating it.

`Runtime_Handle` is a limited type, so prefer direct initialization:

```ada
with Aion.Config;
with Aion.Runtime;

procedure Main is
   function Make_Runtime return Aion.Runtime.Runtime_Handle is
      Config : Aion.Config.Runtime_Config := Aion.Config.Default;
   begin
      Config := Aion.Config.With_Name (Config, "my-aion-app");
      Config := Aion.Config.With_Workers (Config, 4);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 1024);
      Config := Aion.Config.With_Shutdown_Timeout (Config, 2_000);

      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
begin
   null;
end Main;
```

---

## 5. Spawn Runtime Work

Aion runtime work is passed as a procedure access value. Keep job procedures at library level or package level so Ada accessibility rules are satisfied.

`demo_jobs.ads`:

```ada
package Demo_Jobs is
   procedure Print_Message;
end Demo_Jobs;
```

`demo_jobs.adb`:

```ada
with Ada.Text_IO;

package body Demo_Jobs is
   procedure Print_Message is
   begin
      Ada.Text_IO.Put_Line ("Hello from an Aion runtime job.");
   end Print_Message;
end Demo_Jobs;
```

Use the job from your application:

```ada
with Ada.Text_IO;
with Aion.Config;
with Aion.Errors;
with Aion.Runtime;
with Demo_Jobs;

procedure Main is
   Runtime : Aion.Runtime.Runtime_Handle :=
     Aion.Runtime.Create (Aion.Config.Default);

   Started  : Aion.Runtime.Operation_Results.Result_Type;
   Spawned  : Aion.Runtime.Spawn_Results.Result_Type;
   Shutdown : Aion.Runtime.Operation_Results.Result_Type;
begin
   Started := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line ("Runtime start failed.");
      return;
   end if;

   Spawned :=
     Aion.Runtime.Spawn
       (Runtime,
        Name => "demo-job",
        Work => Demo_Jobs.Print_Message'Access);

   if Aion.Runtime.Spawn_Results.Is_Err (Spawned) then
      Ada.Text_IO.Put_Line
        ("Spawn failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Spawn_Results.Error (Spawned)));
   end if;

   Shutdown := Aion.Runtime.Shutdown (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Shutdown) then
      Ada.Text_IO.Put_Line
        ("Runtime shutdown failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Shutdown)));
   end if;
end Main;
```

---

## 6. Futures and Promises

Aion futures are generic and typed. Instantiate a future package for the value type, then instantiate promises with that future package.

```ada
with Ada.Text_IO;
with Aion.Block_On;
with Aion.Future;
with Aion.Promise;

procedure Future_Demo is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);
   package Int_Block_On is new Aion.Block_On.Generic_Block_On (Int_Futures);

   Promise : Int_Promises.Promise_Handle;
   Future  : Int_Futures.Future_Handle;

   Complete_Result : Int_Promises.Operation_Results.Result_Type;
   Await_Result    : Int_Futures.Value_Results.Result_Type;
begin
   Int_Promises.New_Promise (Promise, Future, "answer");

   Complete_Result := Int_Promises.Complete (Promise, 42);
   if Int_Promises.Operation_Results.Is_Err (Complete_Result) then
      Ada.Text_IO.Put_Line ("Promise completion failed.");
      return;
   end if;

   Await_Result := Int_Block_On.Run (Future);
   if Int_Futures.Value_Results.Is_Ok (Await_Result) then
      Ada.Text_IO.Put_Line
        ("Future value:"
         & Integer'Image (Int_Futures.Value_Results.Value (Await_Result)));
   end if;
end Future_Demo;
```

---

## 7. Package Areas

Common packages:

```ada
with Aion.Runtime;
with Aion.Config;
with Aion.Future;
with Aion.Promise;
with Aion.Time;
with Aion.Timeout;
with Aion.Net.TCP;
with Aion.Net.UDP;
with Aion.Channel.Bounded;
with Aion.Channel.Oneshot;
with Aion.Sync.Mutex;
with Aion.Cancel_Source;
with Aion.Cancel_Token;
with Aion.Task_Group;
with Aion.Supervisor;
with Aion.Diagnostics;
with Aion.Metrics;
```

Use bounded channels when you need backpressure, cancellation tokens for graceful shutdown, task groups for owned sets of work, and supervisors for restartable services.

The selector package is named `Aion.Selector`, not `Aion.Select`, because `select` is an Ada reserved word.

---

## 8. Source Checkout Examples

If you cloned the Aion repository and want to run its included examples:

```powershell
cd C:\src\Aion
alr exec -- gprbuild -P aion_examples.gpr
.\bin\runtime_core_demo.exe
.\bin\future_promise_demo.exe
.\bin\channel_demo.exe
.\bin\observability_demo.exe
```

For TCP echo examples, run the server and client in separate terminals:

```powershell
.\bin\echo_server.exe
```

```powershell
.\bin\echo_client.exe
```

---

## 9. Common Mistakes

Do not write:

```ada
import Aion;
```

Use:

```ada
with Aion;
```

Check returned result values. Runtime start, spawn, shutdown, future completion, channel send, and channel receive operations can report errors.

Use `Work =>` when calling `Aion.Runtime.Spawn`, `Aion.Task_Group.Spawn`, or `Aion.Supervisor.Spawn`.

Keep runtime job procedures outside nested scopes when passing `'Access`.

Prefer direct initialization for `Runtime_Handle`; it is a limited type and should not be copied around.
