# Aion Example Usage

This guide gives copyable examples for applications that consume Aion as a library.

Before using these examples, add Aion to your application with one of these methods:

```powershell
alr with aion
```

or, if you pulled Aion manually from GitHub:

```powershell
git clone https://github.com/MaheshChandraTeja/Aion.git C:\src\Aion
alr with aion --use C:\src\Aion
```

For a non-Alire project, add this to your `.gpr` file:

```ada
with "C:\src\Aion\aion.gpr";
```

---

## 1. Minimal Runtime Program

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

   Ada.Text_IO.Put_Line ("Runtime is running.");

   Shutdown := Aion.Runtime.Shutdown (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Shutdown) then
      Ada.Text_IO.Put_Line
        ("Runtime shutdown failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Shutdown)));
   end if;
end Main;
```

Build and run:

```powershell
alr build
alr run
```

---

## 2. Custom Runtime Configuration

```ada
with Ada.Text_IO;
with Aion.Config;
with Aion.Errors;
with Aion.Runtime;

procedure Configured_Runtime is
   function Make_Runtime return Aion.Runtime.Runtime_Handle is
      Config : Aion.Config.Runtime_Config := Aion.Config.Default;
   begin
      Config := Aion.Config.With_Name (Config, "configured-runtime");
      Config := Aion.Config.With_Workers (Config, 4);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 2048);
      Config := Aion.Config.With_Shutdown_Timeout (Config, 2_000);

      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Started : Aion.Runtime.Operation_Results.Result_Type;
   Stopped : Aion.Runtime.Operation_Results.Result_Type;
begin
   Started := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line
        ("Start failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Started)));
      return;
   end if;

   Ada.Text_IO.Put_Line ("Configured runtime started.");

   Stopped := Aion.Runtime.Shutdown (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Stopped) then
      Ada.Text_IO.Put_Line
        ("Shutdown failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Stopped)));
   end if;
end Configured_Runtime;
```

Use a helper function because `Runtime_Handle` is limited and should be initialized directly.

---

## 3. Runtime Job

Create a package for the job.

`demo_jobs.ads`:

```ada
package Demo_Jobs is
   procedure Print_From_Runtime;
end Demo_Jobs;
```

`demo_jobs.adb`:

```ada
with Ada.Text_IO;

package body Demo_Jobs is
   procedure Print_From_Runtime is
   begin
      Ada.Text_IO.Put_Line ("Hello from an Aion runtime job.");
   end Print_From_Runtime;
end Demo_Jobs;
```

Main file:

```ada
with Ada.Text_IO;
with Aion.Config;
with Aion.Errors;
with Aion.Runtime;
with Demo_Jobs;

procedure Runtime_Job_Demo is
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
        Name => "print-job",
        Work => Demo_Jobs.Print_From_Runtime'Access);

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
end Runtime_Job_Demo;
```

Keep runtime jobs at package level when passing `'Access`.

---

## 4. Future and Promise

```ada
with Ada.Text_IO;
with Aion.Block_On;
with Aion.Future;
with Aion.Promise;

procedure Future_Promise_Demo is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);
   package Int_Block_On is new Aion.Block_On.Generic_Block_On (Int_Futures);

   Promise : Int_Promises.Promise_Handle;
   Future  : Int_Futures.Future_Handle;

   Complete_Result : Int_Promises.Operation_Results.Result_Type;
   Await_Result    : Int_Futures.Value_Results.Result_Type;
begin
   Int_Promises.New_Promise (Promise, Future, "demo-future");

   Complete_Result := Int_Promises.Complete (Promise, 2026);
   if Int_Promises.Operation_Results.Is_Err (Complete_Result) then
      Ada.Text_IO.Put_Line ("complete failed");
      return;
   end if;

   Await_Result := Int_Block_On.Run (Future);
   if Int_Futures.Value_Results.Is_Ok (Await_Result) then
      Ada.Text_IO.Put_Line
        ("future value ="
         & Integer'Image (Int_Futures.Value_Results.Value (Await_Result)));
   else
      Ada.Text_IO.Put_Line ("future failed");
   end if;
end Future_Promise_Demo;
```

---

## 5. Await With Timeout

```ada
with Ada.Text_IO;
with Aion.Future;
with Aion.Promise;

procedure Future_Timeout_Demo is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Int_Futures);

   Promise : Int_Promises.Promise_Handle;
   Future  : Int_Futures.Future_Handle;

   Result : Int_Futures.Value_Results.Result_Type;
begin
   Int_Promises.New_Promise (Promise, Future, "timeout-demo");

   Result := Int_Futures.Await_Timeout
     (Future,
      Timeout => 2_000);

   if Int_Futures.Value_Results.Is_Ok (Result) then
      Ada.Text_IO.Put_Line ("Received value.");
   else
      Ada.Text_IO.Put_Line ("Future did not complete before timeout.");
   end if;
end Future_Timeout_Demo;
```

Use timeouts around I/O, joins, and external work where unbounded waits would be unsafe.

---

## 6. Task Group

`task_group_jobs.ads`:

```ada
package Task_Group_Jobs is
   procedure Work;
end Task_Group_Jobs;
```

`task_group_jobs.adb`:

```ada
with Ada.Text_IO;

package body Task_Group_Jobs is
   procedure Work is
   begin
      Ada.Text_IO.Put_Line ("task group work");
   end Work;
end Task_Group_Jobs;
```

Main file:

```ada
with Ada.Text_IO;
with Aion.Errors;
with Aion.Runtime;
with Aion.Task_Group;
with Task_Group_Jobs;

procedure Task_Group_Demo is
   Runtime : aliased Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Group   : Aion.Task_Group.Task_Group (4);

   Started : Aion.Runtime.Operation_Results.Result_Type;
   Spawned : Aion.Runtime.Spawn_Results.Result_Type;
   Joined  : Aion.Task_Group.Operation_Results.Result_Type;
begin
   Started := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line ("Runtime start failed.");
      return;
   end if;

   Aion.Task_Group.Initialize
     (Group,
      Runtime'Unchecked_Access,
      "demo-group");

   Spawned :=
     Aion.Task_Group.Spawn
       (Group,
        Name => "demo-work",
        Work => Task_Group_Jobs.Work'Access);

   if Aion.Runtime.Spawn_Results.Is_Err (Spawned) then
      Ada.Text_IO.Put_Line
        ("Spawn failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Spawn_Results.Error (Spawned)));
   end if;

   Joined := Aion.Task_Group.Join_All (Group, Timeout => 2_000);
   if Aion.Task_Group.Operation_Results.Is_Ok (Joined) then
      Ada.Text_IO.Put_Line ("Task group joined.");
   end if;

   declare
      Shutdown : constant Aion.Runtime.Operation_Results.Result_Type :=
        Aion.Runtime.Shutdown (Runtime);
   begin
      if Aion.Runtime.Operation_Results.Is_Err (Shutdown) then
         Ada.Text_IO.Put_Line
           ("Runtime shutdown failed: "
            & Aion.Errors.Image
                (Aion.Runtime.Operation_Results.Error (Shutdown)));
      end if;
   end;
end Task_Group_Demo;
```

Task groups are useful when a set of runtime jobs should be joined, cancelled, or observed together.

---

## 7. Supervisor

Supervisors manage restartable runtime jobs.

```ada
with Ada.Text_IO;
with Aion.Errors;
with Aion.Runtime;
with Aion.Supervisor;
with Demo_Jobs;

procedure Supervisor_Demo is
   Runtime : aliased Aion.Runtime.Runtime_Handle := Aion.Runtime.Create;
   Sup     : Aion.Supervisor.Supervisor (2);

   Started : Aion.Runtime.Operation_Results.Result_Type;
   Spawned : Aion.Runtime.Spawn_Results.Result_Type;
begin
   Started := Aion.Runtime.Start (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line ("Runtime start failed.");
      return;
   end if;

   Aion.Supervisor.Initialize
     (Sup,
      Runtime'Unchecked_Access,
      "demo-supervisor",
      Config =>
        (Policy           => Aion.Supervisor.Restart_Failed_Children,
         Max_Restarts     => 2,
         Restart_Delay_Ms => 10,
         Join_Timeout_Ms  => 1_000));

   Spawned :=
     Aion.Supervisor.Spawn
       (Sup,
        Name => "worker",
        Work => Demo_Jobs.Print_From_Runtime'Access);

   if Aion.Runtime.Spawn_Results.Is_Ok (Spawned) then
      Ada.Text_IO.Put_Line
        ("Supervisor stats: "
         & Aion.Supervisor.Image (Aion.Supervisor.Stats_Of (Sup)));
   else
      Ada.Text_IO.Put_Line
        ("Supervisor spawn failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Spawn_Results.Error (Spawned)));
   end if;

   Started := Aion.Runtime.Shutdown (Runtime);
   if Aion.Runtime.Operation_Results.Is_Err (Started) then
      Ada.Text_IO.Put_Line
        ("Runtime shutdown failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Started)));
   end if;
end Supervisor_Demo;
```

---

## 8. Repository Examples

If you cloned the Aion repository from GitHub, build the included examples:

```powershell
cd C:\src\Aion
alr exec -- gprbuild -P aion_examples.gpr
```

Run examples:

```powershell
.\bin\runtime_core_demo.exe
.\bin\future_promise_demo.exe
.\bin\timer_demo.exe
.\bin\channel_demo.exe
.\bin\actor_mailbox_demo.exe
.\bin\cancellation_demo.exe
.\bin\task_group_demo.exe
.\bin\supervisor_demo.exe
.\bin\observability_demo.exe
```

Run the TCP echo demo in two terminals.

Terminal 1:

```powershell
.\bin\echo_server.exe
```

Terminal 2:

```powershell
.\bin\echo_client.exe
```

---

## 9. Style Recommendations

Use qualified package names such as `Aion.Runtime.Start`.

Check result values from runtime, future, channel, networking, and shutdown operations.

Use `Work =>` for runtime job parameters.

Use bounded channels when you need backpressure.

Use cancellation tokens and task groups for graceful shutdown.

Use supervisors for restartable services.

Use `with Aion.Selector;`, not `with Aion.Select;`.
