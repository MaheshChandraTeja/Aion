# Aion Example Usage

This guide collects practical examples for using Aion in Ada applications.

Ada imports packages with `with`, not `import`. So the Aion equivalent of `import Aion` is:

```ada
with Aion;
```

For child packages:

```ada
with Aion.Runtime;
with Aion.Config;
with Aion.Future;
```

Ada is extremely literal about this. It will not guess what you meant, because guessing is how civilizations invented JavaScript dependency trees.

---

## 1. Minimal Aion Application

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

Build:

```powershell
alr build
alr run
```

---

## 2. Runtime With Custom Configuration

```ada
with Ada.Text_IO;
with Aion.Config;
with Aion.Runtime;
with Aion.Errors;

procedure Configured_Runtime is

   function Make_Runtime return Aion.Runtime.Runtime_Handle is
      Config : Aion.Config.Runtime_Config := Aion.Config.Default;
   begin
      Config := Aion.Config.With_Name (Config, "configured-runtime");
      Config := Aion.Config.With_Workers (Config, 4);
      Config := Aion.Config.With_Max_Queue_Depth (Config, 2048);

      return Aion.Runtime.Create (Config);
   end Make_Runtime;

   Runtime : Aion.Runtime.Runtime_Handle := Make_Runtime;
   Result  : Aion.Runtime.Operation_Results.Result_Type;

begin
   Ada.Text_IO.Put_Line ("Configured runtime created.");

   Result := Aion.Runtime.Shutdown (Runtime);

   if Aion.Runtime.Operation_Results.Is_Ok (Result) then
      Ada.Text_IO.Put_Line ("Shutdown complete.");
   else
      Ada.Text_IO.Put_Line
        ("Shutdown failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Result)));
   end if;
end Configured_Runtime;
```

Why use `Make_Runtime`? Because `Runtime_Handle` is limited. Ada does not let you casually assign runtime ownership later, which is annoying in exactly the way seatbelts are annoying.

---

## 3. Runtime Job Example

Create a job package.

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
with Aion.Runtime;
with Aion.Errors;
with Demo_Jobs;

procedure Runtime_Job_Demo is
   Config  : constant Aion.Config.Runtime_Config := Aion.Config.Default;
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create (Config);

   Spawn_Result    : Aion.Runtime.Operation_Results.Result_Type;
   Shutdown_Result : Aion.Runtime.Operation_Results.Result_Type;
begin
   Spawn_Result :=
     Aion.Runtime.Spawn
       (Runtime,
        Name => "print-job",
        Job  => Demo_Jobs.Print_From_Runtime'Access);

   if not Aion.Runtime.Operation_Results.Is_Ok (Spawn_Result) then
      Ada.Text_IO.Put_Line
        ("Spawn failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Spawn_Result)));
   end if;

   Shutdown_Result := Aion.Runtime.Shutdown (Runtime);

   if Aion.Runtime.Operation_Results.Is_Ok (Shutdown_Result) then
      Ada.Text_IO.Put_Line ("Runtime shut down.");
   end if;
end Runtime_Job_Demo;
```

Important: runtime job procedures should usually be library-level procedures or package-level procedures. Passing nested procedures with `'Access` often triggers Ada accessibility errors, because Ada has opinions about lifetimes and insists on sharing them.

---

## 4. Future and Promise Example

```ada
with Ada.Text_IO;
with Aion.Future;
with Aion.Promise;
with Aion.Errors;

procedure Future_Promise_Demo is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Integer);

   Pair : Int_Promises.Promise_Future_Pair :=
     Int_Promises.Create;

   Completion : Int_Futures.Value_Results.Result_Type;
   Awaited    : Int_Futures.Value_Results.Result_Type;
begin
   Completion := Int_Promises.Complete_Success (Pair.Promise, 42);

   if not Int_Futures.Value_Results.Is_Ok (Completion) then
      Ada.Text_IO.Put_Line ("Failed to complete promise.");
      return;
   end if;

   Awaited := Int_Futures.Await (Pair.Future);

   if Int_Futures.Value_Results.Is_Ok (Awaited) then
      Ada.Text_IO.Put_Line
        ("Future value:"
         & Integer'Image (Int_Futures.Value_Results.Value (Awaited)));
   else
      Ada.Text_IO.Put_Line
        ("Await failed: "
         & Aion.Errors.Image
             (Int_Futures.Value_Results.Error (Awaited)));
   end if;
end Future_Promise_Demo;
```

Typed futures keep payloads safe and explicit. It is more ceremony than a dynamic language, but fewer bugs survive the compiler gauntlet.

---

## 5. Timeout-Oriented Future Example

Aion timeout APIs are built around typed futures. The exact instantiation depends on the future type.

Example pattern:

```ada
with Ada.Text_IO;
with Aion.Future;
with Aion.Promise;
with Aion.Timeout;
with Aion.Errors;

procedure Timeout_Pattern_Demo is
   package Int_Futures is new Aion.Future.Generic_Future (Integer);
   package Int_Promises is new Aion.Promise.Generic_Promise (Integer);

   Pair : Int_Promises.Promise_Future_Pair :=
     Int_Promises.Create;

   Result : Int_Futures.Value_Results.Result_Type;
begin
   Result := Int_Futures.Await_With_Timeout
     (Pair.Future,
      Timeout_MS => 2_000);

   if Int_Futures.Value_Results.Is_Ok (Result) then
      Ada.Text_IO.Put_Line ("Received value.");
   else
      Ada.Text_IO.Put_Line
        ("Timed out or failed: "
         & Aion.Errors.Image
             (Int_Futures.Value_Results.Error (Result)));
   end if;
end Timeout_Pattern_Demo;
```

Use timeouts on external I/O, task joins, and inter-task communication. Unbounded waits are where nice services go to become incident reports.

---

## 6. Bounded Channel Example

```ada
with Ada.Text_IO;
with Aion.Channel.Bounded;
with Aion.Errors;

procedure Bounded_Channel_Demo is
   package Int_Channels is new Aion.Channel.Bounded.Generic_Bounded_Channel
     (Element_Type => Integer);

   Channel : Int_Channels.Channel_Handle :=
     Int_Channels.Create (Capacity => 8);

   Send_Result : Int_Channels.Operation_Results.Result_Type;
   Recv_Result : Int_Channels.Receive_Results.Result_Type;
begin
   Send_Result := Int_Channels.Try_Send (Channel, 100);

   if not Int_Channels.Operation_Results.Is_Ok (Send_Result) then
      Ada.Text_IO.Put_Line ("Send failed.");
      return;
   end if;

   Recv_Result := Int_Channels.Try_Receive (Channel);

   if Int_Channels.Receive_Results.Is_Ok (Recv_Result) then
      Ada.Text_IO.Put_Line
        ("Received:"
         & Integer'Image
             (Int_Channels.Receive_Results.Value (Recv_Result)));
   else
      Ada.Text_IO.Put_Line
        ("Receive failed: "
         & Aion.Errors.Image
             (Int_Channels.Receive_Results.Error (Recv_Result)));
   end if;
end Bounded_Channel_Demo;
```

Use bounded channels when possible. They enforce backpressure. Backpressure is just the system saying “please stop pouring requests into my mouth.”

---

## 7. Oneshot Channel Example

```ada
with Ada.Text_IO;
with Aion.Channel.Oneshot;
with Aion.Errors;

procedure Oneshot_Demo is
   package String_Oneshot is new Aion.Channel.Oneshot.Generic_Oneshot_Channel
     (Element_Type => String);

   Pair : String_Oneshot.Channel_Pair := String_Oneshot.Create;

   Send_Result : String_Oneshot.Operation_Results.Result_Type;
   Recv_Result : String_Oneshot.Receive_Results.Result_Type;
begin
   Send_Result := String_Oneshot.Send (Pair.Sender, "done");

   if not String_Oneshot.Operation_Results.Is_Ok (Send_Result) then
      Ada.Text_IO.Put_Line ("Oneshot send failed.");
      return;
   end if;

   Recv_Result := String_Oneshot.Receive (Pair.Receiver);

   if String_Oneshot.Receive_Results.Is_Ok (Recv_Result) then
      Ada.Text_IO.Put_Line
        ("Oneshot value: "
         & String_Oneshot.Receive_Results.Value (Recv_Result));
   else
      Ada.Text_IO.Put_Line
        ("Oneshot receive failed: "
         & Aion.Errors.Image
             (String_Oneshot.Receive_Results.Error (Recv_Result)));
   end if;
end Oneshot_Demo;
```

Use oneshot channels for single completion messages: task finished, operation completed, one reply arrived, or a supervisor reported an outcome.

---

## 8. Cancellation Token Example

```ada
with Ada.Text_IO;
with Aion.Cancel_Source;
with Aion.Cancel_Token;

procedure Cancellation_Demo is
   Source : constant Aion.Cancel_Source.Cancel_Source_Handle :=
     Aion.Cancel_Source.Create;

   Token : constant Aion.Cancel_Token.Cancel_Token_Handle :=
     Aion.Cancel_Source.Token (Source);
begin
   if not Aion.Cancel_Token.Is_Cancelled (Token) then
      Ada.Text_IO.Put_Line ("Token is active.");
   end if;

   Aion.Cancel_Source.Cancel (Source);

   if Aion.Cancel_Token.Is_Cancelled (Token) then
      Ada.Text_IO.Put_Line ("Token is cancelled.");
   end if;
end Cancellation_Demo;
```

Cancellation should be cooperative. That means tasks check tokens at safe points and exit cleanly. It is not a magic hammer that bonks tasks out of existence.

---

## 9. Task Group Example

```ada
with Ada.Text_IO;
with Aion.Config;
with Aion.Runtime;
with Aion.Task_Group;
with Demo_Jobs;

procedure Task_Group_Demo is
   Config  : constant Aion.Config.Runtime_Config := Aion.Config.Default;
   Runtime : Aion.Runtime.Runtime_Handle := Aion.Runtime.Create (Config);

   Group : Aion.Task_Group.Task_Group_Handle :=
     Aion.Task_Group.Create (Runtime);

   Result : Aion.Task_Group.Operation_Results.Result_Type;
begin
   Result :=
     Aion.Task_Group.Spawn
       (Group,
        Name => "worker-one",
        Job  => Demo_Jobs.Print_From_Runtime'Access);

   Result := Aion.Task_Group.Join_All (Group);

   if Aion.Task_Group.Operation_Results.Is_Ok (Result) then
      Ada.Text_IO.Put_Line ("Task group completed.");
   end if;

   Result := Aion.Runtime.Shutdown (Runtime);
end Task_Group_Demo;
```

Task groups help ensure spawned work is joined, cancelled, or accounted for. They are the antidote to “where did that background task come from?” which is a sentence no healthy system should inspire.

---

## 10. Supervisor Example

Supervisors restart or manage failing tasks based on policy.

Typical use:

```ada
with Ada.Text_IO;
with Aion.Supervisor;
with Aion.Config;
with Aion.Runtime;
with Demo_Jobs;

procedure Supervisor_Demo is
   Runtime : Aion.Runtime.Runtime_Handle :=
     Aion.Runtime.Create (Aion.Config.Default);

   Supervisor : Aion.Supervisor.Supervisor_Handle :=
     Aion.Supervisor.Create
       (Runtime,
        Name => "demo-supervisor");

   Result : Aion.Supervisor.Operation_Results.Result_Type;
begin
   Result :=
     Aion.Supervisor.Spawn
       (Supervisor,
        Name => "supervised-worker",
        Job  => Demo_Jobs.Print_From_Runtime'Access);

   if Aion.Supervisor.Operation_Results.Is_Ok (Result) then
      Ada.Text_IO.Put_Line ("Supervised worker started.");
   end if;

   Result := Aion.Supervisor.Shutdown (Supervisor);
   Result := Aion.Runtime.Shutdown (Runtime);
end Supervisor_Demo;
```

Use supervisors for long-running services, worker pools, restartable protocol handlers, and background processors.

---

## 11. TCP Echo Server and Client

Build examples:

```powershell
alr exec -- gprbuild -P aion_examples.gpr
```

Run the server in terminal 1:

```powershell
cd F:\Projects-INT\Aion
.\bin\echo_server.exe
```

Run the client in terminal 2:

```powershell
cd F:\Projects-INT\Aion
.\bin\echo_client.exe
```

Expected flow:

```text
server: listening on 127.0.0.1:9090
client: connected
client: sent payload
server: echoed payload
client: received echo
```

If the client times out, make sure the server is still running. Running server and client sequentially in the same terminal usually means the server exits before the client connects. Causality, the final boss.

---

## 12. Observability Example

```ada
with Ada.Text_IO;
with Aion.Diagnostics;
with Aion.Metrics;

procedure Observability_Demo is
begin
   Ada.Text_IO.Put_Line ("Aion diagnostics:");
   Ada.Text_IO.Put_Line (Aion.Diagnostics.Summary);
end Observability_Demo;
```

Use observability in real applications to expose:

- runtime configuration,
- scheduler stats,
- reactor state,
- timer counts,
- channel activity,
- cancellation status,
- release/build information.

A system that cannot describe its own state is not reliable. It is merely quiet.

---

## 13. Consumer Project Example

Create a separate app:

```powershell
cd C:\Users\MarshFang\Downloads
alr init --bin aion_consumer
cd aion_consumer
alr with aion --use F:\Projects-INT\Aion
```

Replace `src/aion_consumer.adb`:

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

Run:

```powershell
alr build
alr run
```

Expected:

```text
Using Aion
Aion is a structured asynchronous runtime and scheduler foundation for Ada.
Aion runtime created successfully.
Runtime shut down successfully.
```

---

## 14. Example Build Checklist

From the Aion root:

```powershell
alr exec -- gprbuild -P aion.gpr
alr exec -- gprbuild -P aion_examples.gpr
alr exec -- gprbuild -P aion_tests.gpr
alr exec -- gprbuild -P aion_benchmarks.gpr
```

Run examples:

```powershell
.\bin\aion_module1_app.exe
.\bin\runtime_core_demo.exe
.\bin\future_promise_demo.exe
.\bin\timer_demo.exe
.\bin\channel_demo.exe
.\bin\actor_mailbox_demo.exe
.\bin\cancellation_demo.exe
.\bin\observability_demo.exe
```

---

## 15. Style Recommendations

When writing applications on Aion:

- keep Aion package names qualified,
- avoid nested callbacks for runtime jobs,
- check every result value,
- prefer bounded queues/channels,
- use task groups for related work,
- use cancellation tokens for graceful shutdown,
- use diagnostics in examples and real services,
- keep demos warning-free,
- build tests before benchmarks,
- do not use unbounded anything casually.

Concurrency bugs are already creative enough. Do not give them better tools.
