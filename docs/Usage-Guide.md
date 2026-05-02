# Aion Usage Guide

This guide shows how to use Aion as an Ada library in a real project. It assumes Aion is available either as a local Alire dependency or as a packaged crate.

Ada does not use `import Aion`. Ada uses:

```ada
with Aion;
```

Yes, the keyword is `with`. Ada picked its own vocabulary and then committed to the bit for decades. We respect the dedication.

---

## 1. Basic Import Pattern

To use Aion packages, add `with` clauses at the top of your Ada unit:

```ada
with Aion;
with Aion.Config;
with Aion.Runtime;
```

Then reference names through their package:

```ada
Aion.Name
Aion.Config.Default
Aion.Runtime.Create
```

Recommended style:

```ada
with Aion;
with Aion.Config;
with Aion.Runtime;

procedure Main is
begin
   -- Use qualified names.
end Main;
```

Avoid broad `use` clauses in larger applications unless the package is small and local. Qualified names make runtime code easier to audit.

---

## 2. Minimal Runtime Program

```ada
with Ada.Text_IO;
with Aion;
with Aion.Config;
with Aion.Runtime;
with Aion.Errors;

procedure Main is
   Config  : constant Aion.Config.Runtime_Config := Aion.Config.Default;
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create (Config);

   Shutdown_Result : Aion.Runtime.Operation_Results.Result_Type;
begin
   Aion.Initialize;

   Ada.Text_IO.Put_Line ("Using " & Aion.Name);
   Ada.Text_IO.Put_Line (Aion.Description);
   Ada.Text_IO.Put_Line ("Runtime created successfully.");

   Shutdown_Result := Aion.Runtime.Shutdown (Runtime);

   if Aion.Runtime.Operation_Results.Is_Ok (Shutdown_Result) then
      Ada.Text_IO.Put_Line ("Runtime shut down successfully.");
   else
      Ada.Text_IO.Put_Line
        ("Runtime shutdown failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Shutdown_Result)));
   end if;
end Main;
```

This is the smallest useful Aion application: create configuration, create runtime, shut it down safely.

---

## 3. Runtime Configuration

Aion uses `Aion.Config.Runtime_Config` to configure runtime behavior.

Typical pattern:

```ada
with Aion.Config;
with Aion.Runtime;

procedure Main is
   Config  : Aion.Config.Runtime_Config := Aion.Config.Default;
   Runtime : Aion.Runtime.Runtime_Handle;
begin
   Config := Aion.Config.With_Name (Config, "my-aion-app");
   Config := Aion.Config.With_Workers (Config, 4);
   Config := Aion.Config.With_Max_Queue_Depth (Config, 1024);

   Runtime := Aion.Runtime.Create (Config);
end Main;
```

However, be careful: `Runtime_Handle` is a limited type. You usually cannot assign it after declaration. Prefer direct initialization through a helper function:

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

      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
begin
   null;
end Main;
```

Ada limited types prevent accidental copying of runtime ownership. It feels fussy until it prevents an entire class of lifecycle bugs. Then it feels fussy and useful.

---

## 4. Spawning Runtime Jobs

Aion runtime jobs are procedures. For simple examples, use library-level job procedures. Avoid deeply nested procedures when passing access values, because Ada enforces accessibility rules.

Example job package:

```ada
package Demo_Jobs is
   procedure Print_Message;
end Demo_Jobs;
```

```ada
with Ada.Text_IO;

package body Demo_Jobs is
   procedure Print_Message is
   begin
      Ada.Text_IO.Put_Line ("Hello from an Aion runtime job.");
   end Print_Message;
end Demo_Jobs;
```

Use it from an app:

```ada
with Ada.Text_IO;
with Aion.Config;
with Aion.Runtime;
with Aion.Errors;
with Demo_Jobs;

procedure Main is
   Config  : constant Aion.Config.Runtime_Config := Aion.Config.Default;
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create (Config);

   Spawn_Result    : Aion.Runtime.Operation_Results.Result_Type;
   Shutdown_Result : Aion.Runtime.Operation_Results.Result_Type;
begin
   Spawn_Result :=
     Aion.Runtime.Spawn
       (Runtime,
        Name => "demo-job",
        Job  => Demo_Jobs.Print_Message'Access);

   if not Aion.Runtime.Operation_Results.Is_Ok (Spawn_Result) then
      Ada.Text_IO.Put_Line
        ("Spawn failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Spawn_Result)));
   end if;

   Shutdown_Result := Aion.Runtime.Shutdown (Runtime);
end Main;
```

If Ada complains that a subprogram is too deep for an access type, move the job procedure into a library-level package. That is Ada saving you from lifetime bugs while somehow making you feel personally judged.

---

## 5. Futures and Promises

Aion futures are generic and typed. You instantiate them for the value type you want.

Example:

```ada
with Ada.Text_IO;
with Aion.Future;
with Aion.Promise;
with Aion.Errors;

procedure Future_Demo is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Integer);

   Pair : Int_Promises.Promise_Future_Pair :=
     Int_Promises.Create;

   Completed : Int_Futures.Value_Results.Result_Type;
begin
   Completed := Int_Promises.Complete_Success (Pair.Promise, 42);

   if Int_Futures.Value_Results.Is_Ok (Completed) then
      Ada.Text_IO.Put_Line ("Future completed.");
   else
      Ada.Text_IO.Put_Line
        ("Future failed: "
         & Aion.Errors.Image
             (Int_Futures.Value_Results.Error (Completed)));
   end if;
end Future_Demo;
```

Typed futures are more verbose than dynamic payloads, but the compiler knows what is inside them. This is generally better than finding out at runtime that your “message” was actually a swamp.

---

## 6. Timers and Timeouts

Aion provides timer-oriented packages:

```ada
with Aion.Time;
with Aion.Sleep;
with Aion.Timeout;
with Aion.Interval;
with Aion.Deadline;
```

A simple sleep-style call should look like:

```ada
Aion.Time.Sleep_For (Milliseconds => 500);
```

Timeouts wrap operations with a maximum wait period. In real applications, prefer timeout-aware APIs around futures and networking operations rather than unbounded waits.

Example idea:

```ada
-- Pseudocode-shaped example:
Result := Aion.Timeout.Await_With_Timeout
  (Future,
   Timeout_MS => 2_000);
```

Exact usage depends on the instantiated future type.

---

## 7. Async Networking

Aion networking is exposed through:

```ada
with Aion.Net;
with Aion.Net.Address;
with Aion.Net.TCP;
with Aion.Net.TCP_Listener;
with Aion.Net.TCP_Stream;
with Aion.Net.UDP;
```

Typical flow:

```text
Create address
Create runtime
Bind listener or connect stream
Await accept/connect result
Read/write through stream futures
Close stream
Shutdown runtime
```

The included examples demonstrate:

```text
examples/echo_server.adb
examples/echo_client.adb
examples/tcp_timeout_demo.adb
examples/udp_ping_pong.adb
```

Run the echo server and client in separate terminals:

```powershell
cd F:\Projects-INT\Aion
.\bin\echo_server.exe
```

Second terminal:

```powershell
cd F:\Projects-INT\Aion
.\bin\echo_client.exe
```

A server must remain running while the client connects. Computers remain stubborn about causality.

---

## 8. Synchronization Primitives

Aion provides async-aware synchronization packages:

```ada
with Aion.Sync;
with Aion.Sync.Mutex;
with Aion.Sync.Semaphore;
with Aion.Sync.Event;
with Aion.Sync.Condvar;
with Aion.Sync.Barrier;
with Aion.Sync.RWLock;
with Aion.Sync.Once;
```

Use these when coordinating Aion runtime tasks. They are intended to cooperate with Aion’s future/waker/runtime model.

Examples are in:

```text
examples/sync_primitives_demo.adb
```

---

## 9. Channels and Actors

Aion provides typed communication packages:

```ada
with Aion.Channel;
with Aion.Channel.Bounded;
with Aion.Channel.Unbounded;
with Aion.Channel.Oneshot;
with Aion.Channel.Broadcast;
with Aion.Channel.Watch;
with Aion.Stream;
with Aion.Actor;
with Aion.Selector;
```

Use bounded channels when you need backpressure. Use unbounded channels sparingly. “Unbounded” means “it can eat memory until the machine starts writing poetry in swap.”

Example files:

```text
examples/channel_demo.adb
examples/actor_mailbox_demo.adb
examples/select_demo.adb
```

Important: the selector package is named `Aion.Selector`, not `Aion.Select`, because `select` is reserved in Ada.

---

## 10. Cancellation and Structured Concurrency

Aion provides structured concurrency through:

```ada
with Aion.Cancel;
with Aion.Cancel_Token;
with Aion.Cancel_Source;
with Aion.Task_Group;
with Aion.Join_Set;
with Aion.Supervisor;
with Aion.Scope;
with Aion.Retry;
```

Use these packages to avoid orphaned tasks and unmanaged shutdown behavior.

Examples:

```text
examples/cancellation_demo.adb
examples/task_group_demo.adb
examples/supervisor_demo.adb
```

A good Aion application should prefer:

```text
Task group / scope / supervisor
```

over:

```text
spawn everything and hope
```

Hope is not a concurrency primitive.

---

## 11. Observability

Aion provides observability through:

```ada
with Aion.Metrics;
with Aion.Tracing;
with Aion.Diagnostics;
with Aion.Test_Support;
with Aion.Benchmark_Support;
```

Use diagnostics to produce human-readable runtime and build information. Use metrics snapshots to inspect subsystem behavior.

Examples:

```text
examples/observability_demo.adb
examples/release_diagnostics_demo.adb
```

Benchmarks:

```text
benchmarks/bench_scheduler.adb
benchmarks/bench_spawn.adb
benchmarks/bench_timers.adb
benchmarks/bench_channels.adb
benchmarks/bench_tcp_echo.adb
benchmarks/bench_cancellation.adb
benchmarks/bench_reactor.adb
```

---

## 12. Building Aion

Build the library:

```powershell
alr exec -- gprbuild -P aion.gpr
```

Build examples:

```powershell
alr exec -- gprbuild -P aion_examples.gpr
```

Build tests:

```powershell
alr exec -- gprbuild -P aion_tests.gpr
```

Build benchmarks:

```powershell
alr exec -- gprbuild -P aion_benchmarks.gpr
```

If `gprbuild` is not recognized directly, use `alr exec -- gprbuild`. Alire manages the toolchain environment. Windows PATH, naturally, prefers drama.

---

## 13. Running Tests

```powershell
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
```

If the binary is not in `bin`, locate it:

```powershell
Get-ChildItem -Recurse -Filter "test_runner.exe"
```

---

## 14. Running Benchmarks

```powershell
alr exec -- gprbuild -P aion_benchmarks.gpr
.\bin\bench_scheduler.exe
.\bin\bench_spawn.exe
.\bin\bench_timers.exe
.\bin\bench_channels.exe
.\bin\bench_cancellation.exe
.\bin\bench_reactor.exe
.\bin\bench_tcp_echo.exe
```

---

## 15. Recommended Application Structure

A clean Aion consumer project can use:

```text
my_app/
├── alire.toml
├── my_app.gpr
└── src/
    ├── my_app.adb
    ├── app_jobs.ads
    ├── app_jobs.adb
    ├── app_config.ads
    └── app_config.adb
```

Keep runtime job procedures in library-level packages when passing `'Access`.

This avoids Ada accessibility errors and keeps runtime entry points clear.

---

## 16. Common Mistakes

### Mistake: using `import Aion`

Use:

```ada
with Aion;
```

### Mistake: ignoring function results

If `Shutdown` returns a result, store and check it:

```ada
Shutdown_Result := Aion.Runtime.Shutdown (Runtime);
```

### Mistake: assigning limited runtime handles

Prefer direct initialization:

```ada
Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create (Config);
```

### Mistake: nested job procedure access

Move callback procedures into a package-level unit.

### Mistake: using `Aion.Select`

Use:

```ada
with Aion.Selector;
```

### Mistake: running echo server and client sequentially in the same terminal

Run the server in one terminal and the client in another.

---

## 17. Practical Development Loop

For day-to-day development:

```powershell
alr exec -- gprbuild -P aion.gpr
alr exec -- gprbuild -P aion_examples.gpr
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
alr exec -- gprbuild -P aion_benchmarks.gpr
```

For a clean rebuild:

```powershell
Remove-Item .\obj -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\bin -Recurse -Force -ErrorAction SilentlyContinue

alr exec -- gprbuild -P aion.gpr
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
```

---

## 18. Recommended Usage Style

For serious applications:

- keep package names qualified,
- check every result,
- avoid hidden global runtime state,
- use bounded channels by default,
- use task groups/scopes for lifecycle ownership,
- use supervisors for restartable services,
- expose diagnostics in your app,
- keep examples and tests warning-free.

The runtime should make concurrency safer, not merely easier to type. Easier-to-type bugs are still bugs. They just arrive faster.
