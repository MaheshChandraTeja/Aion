# Aion

### Structured Asynchronous Runtime for Ada

![Ada](https://img.shields.io/badge/Ada-2022-blue)
![Runtime](https://img.shields.io/badge/runtime-async%20scheduler-purple)
![Build](https://img.shields.io/badge/build-GPRbuild%20%2B%20Alire-brightgreen)
![Library](https://img.shields.io/badge/type-library-informational)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

**Aion** is a structured asynchronous runtime for Ada, built for reliable scheduling, typed futures, timers, networking, async synchronization, channels, cancellation-safe task orchestration, diagnostics, and benchmarkable systems software.

It is designed for developers who want modern async runtime ergonomics without throwing away Ada’s best qualities: strong typing, explicit package boundaries, safe concurrency primitives, deterministic ownership, and a compiler that behaves like a suspicious aerospace auditor.

No fake magic.  
No hidden event-loop circus.  
No “spawn and pray” concurrency.  
Just structured async systems programming for Ada.

---

## Overview

**Aion** brings a Tokio-inspired runtime model into Ada, but it does not try to copy Rust line by line. That would be architectural cosplay, and frankly Ada deserves better.

Aion provides:

- runtime-managed task execution
- cooperative scheduling
- task handles and runtime statistics
- typed futures and promises
- blocking bridges for synchronous code
- sleep, interval, timeout, and deadline utilities
- timer queues and fake clocks for deterministic testing
- async I/O reactor abstraction
- TCP and UDP networking APIs
- async-aware mutexes, semaphores, events, condition variables, barriers, read/write locks, and once cells
- bounded, unbounded, oneshot, broadcast, and watch channels
- stream and actor mailbox utilities
- selector-style waiting across async operations
- cancellation tokens and cancellation sources
- task groups, join sets, scopes, supervisors, and retry hooks
- metrics, tracing, diagnostics, test support, and benchmarks
- Alire/GPRbuild packaging as a reusable Ada library

Aion is built around a simple idea:

> Ada already has serious concurrency tools. Aion adds the runtime layer that makes them easier to compose into modern async applications.

---

## Table of Contents

- [What Is Aion?](#what-is-aion)
- [Why Aion Exists](#why-aion-exists)
- [Design Philosophy](#design-philosophy)
- [Feature Matrix](#feature-matrix)
- [Architecture](#architecture)
- [Runtime Model](#runtime-model)
- [Package Map](#package-map)
- [Installation](#installation)
- [Using Aion as a Library](#using-aion-as-a-library)
- [Quick Start](#quick-start)
- [Examples](#examples)
- [Testing](#testing)
- [Benchmarks](#benchmarks)
- [Repository Layout](#repository-layout)
- [Documentation](#documentation)
- [Research Motivation](#research-motivation)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Authors](#authors)
- [About Kairais Tech](#about-kairais-tech)
- [License](#license)
- [Closing Note](#closing-note)

---

## What Is Aion?

**Aion** is an Ada async runtime foundation.

It gives Ada applications a structured way to run asynchronous work, coordinate tasks, wait on futures, schedule timers, manage networking readiness, communicate through channels, propagate cancellation, supervise task groups, and inspect runtime behavior.

Aion is not just a wrapper around Ada `task` declarations. It is a layered runtime system with explicit lifecycle management.

Aion is useful for:

- network services
- protocol tools
- robotics diagnostics
- telemetry agents
- embedded Linux utilities
- industrial automation
- simulation systems
- local developer tools
- reliability-oriented infrastructure
- research into async runtime design for Ada

It is designed to be used as a library:

```ada
with Aion;
with Aion.Config;
with Aion.Runtime;
```

Ada does not use `import Aion`. It uses `with Aion;`. Ada picked its own vocabulary and then defended it with the intensity of a constitutional monarchy.

---

## Why Aion Exists

Modern async runtimes make systems programming easier by giving developers a consistent model for:

- spawning work
- waiting for results
- handling timeouts
- reacting to I/O readiness
- passing messages
- cancelling work
- supervising failures
- shutting down safely

Ada already has many low-level concurrency strengths, but it does not have a single widely adopted, batteries-included async runtime experience comparable in spirit to Tokio.

Aion explores that space.

The core question is:

> What would a modern async runtime look like if it respected Ada’s language design instead of pretending Ada is Rust with different punctuation?

Aion’s answer:

```text
Use Ada tasks where they make sense.
Use protected objects for safe shared state.
Use generic packages for typed futures and channels.
Use explicit result types.
Use runtime-owned services.
Use structured cancellation.
Expose diagnostics.
Avoid hidden global magic.
```

Because if an async runtime cannot shut down cleanly or explain what it is doing, it is not a runtime. It is a haunted scheduling appliance.

---

## Design Philosophy

| Principle | Meaning |
|---|---|
| Ada-native | Aion uses Ada packages, records, protected objects, tasks, access rules, and generics naturally. |
| Structured | Work should be spawned, joined, cancelled, supervised, and accounted for. |
| Runtime-owned | Timers, reactor events, workers, and shutdown paths belong to the runtime. |
| Typed | Futures, channels, and results should carry real Ada types, not mystery payloads. |
| Observable | Runtime state should be inspectable through metrics, tracing, diagnostics, and benchmarks. |
| Local-first | Aion is a local library. No cloud service. No telemetry. No runtime phoning home like a nervous appliance. |
| Modular | Each subsystem has a clear package boundary and reuses earlier modules. |
| Production-minded | Clean shutdown, deterministic testing, warnings, documentation, and examples matter. |

Aion is built to be serious without becoming joyless. Ada already handles that department.

---

## Feature Matrix

| Area | Capability | Status |
|---|---|---:|
| Core API | versioning, config, errors, generic results | ✅ |
| Runtime | runtime handle, worker model, lifecycle, shutdown | ✅ |
| Scheduler | queueing, task IDs, task handles, stats | ✅ |
| Futures | typed futures, promises, await, polling, block-on | ✅ |
| Timers | sleep, timeout, interval, deadline, fake clock | ✅ |
| Reactor | readiness abstraction, I/O resources, tokens, backend stats | ✅ |
| Networking | TCP listener, TCP stream, UDP socket, address helpers | ✅ |
| Sync | mutex, semaphore, event, condvar, barrier, RWLock, once | ✅ |
| Channels | bounded, unbounded, oneshot, broadcast, watch | ✅ |
| Actors | typed actor mailbox utilities | ✅ |
| Selector | wait across multiple future-like operations | ✅ |
| Cancellation | token, source, task group, join set, scope | ✅ |
| Supervision | supervisor, restart policy hooks, retry helpers | ✅ |
| Observability | metrics, tracing, diagnostics, test support | ✅ |
| Benchmarks | scheduler, spawn, timers, channels, reactor, cancellation | ✅ |
| Packaging | Alire + GPRbuild library usage | ✅ |
| Native I/O Backends | IOCP / epoll / kqueue backend expansion | Planned |
| TLS/DNS Utilities | secure networking helpers | Planned |
| Generated API Docs | full API reference generation | Planned |

Legend:

```text
✅ implemented or scaffolded into the runtime package surface
Planned = architecture prepared, deeper implementation pending
```

---

## Architecture

Aion is organized as a layered runtime.

```text
┌───────────────────────────────────────────────────────────────┐
│ Applications, Examples, User Services                         │
├───────────────────────────────────────────────────────────────┤
│ Structured Concurrency: Scope, Task_Group, Join_Set, Retry    │
├───────────────────────────────────────────────────────────────┤
│ Channels, Streams, Actor Mailboxes, Selector                  │
├───────────────────────────────────────────────────────────────┤
│ Async Sync: Mutex, Semaphore, Event, Condvar, Barrier, RWLock │
├───────────────────────────────────────────────────────────────┤
│ Async Networking: TCP, UDP, Addressing, Socket Options         │
├───────────────────────────────────────────────────────────────┤
│ Reactor: I/O Tokens, Resources, Readiness, Platform Backends   │
├───────────────────────────────────────────────────────────────┤
│ Time: Sleep, Timeout, Interval, Deadline, Timer Queue, Clock   │
├───────────────────────────────────────────────────────────────┤
│ Future Model: Future, Promise, Awaitable, Poll, Block_On       │
├───────────────────────────────────────────────────────────────┤
│ Runtime Core: Runtime, Scheduler, Task Handles, Wakers         │
├───────────────────────────────────────────────────────────────┤
│ Foundation: Types, Errors, Config, Result, Version, Internal   │
└───────────────────────────────────────────────────────────────┘
```

Each layer builds upward. Later modules reuse earlier modules instead of inventing their own private queues, error types, timeout types, or lifecycle machinery.

That matters because duplicated async infrastructure is how projects become archaeology with stack traces.

---

## Runtime Model

Aion applications follow a clear lifecycle:

```text
Create configuration
        ↓
Create runtime
        ↓
Spawn work / create futures / use channels / start services
        ↓
Run or await work
        ↓
Inspect task/runtime state
        ↓
Propagate cancellation if needed
        ↓
Shutdown runtime
        ↓
Check shutdown result
```

The runtime owns:

- worker tasks
- scheduling queues
- task handles
- runtime statistics
- timer integration
- reactor integration
- shutdown coordination

Aion’s runtime design avoids unmanaged background systems. If a service runs in the background, it should be visible, owned, and shut down intentionally.

---

## Package Map

### Foundation

```text
Aion
Aion.Types
Aion.Errors
Aion.Config
Aion.Version
Aion.Result
Aion.Internal
```

### Runtime and Scheduling

```text
Aion.Runtime
Aion.Runtime.Builder
Aion.Scheduler
Aion.Task_Handle
Aion.Task_Id
Aion.Waker
Aion.Yield
Aion.Shutdown
```

### Futures

```text
Aion.Future
Aion.Promise
Aion.Awaitable
Aion.Completion
Aion.Poll
Aion.Block_On
```

### Time

```text
Aion.Time
Aion.Sleep
Aion.Timeout
Aion.Interval
Aion.Deadline
Aion.Clock
Aion.Clock_Fake
Aion.Timer_Queue
```

### Reactor

```text
Aion.Reactor
Aion.Reactor_Backend
Aion.Readiness
Aion.IO_Resource
Aion.IO_Token
Aion.Platform
Aion.Platform.Windows
Aion.Platform.Linux
Aion.Platform.Darwin
```

### Networking

```text
Aion.Net
Aion.Net.Address
Aion.Net.Socket_Options
Aion.Net.TCP
Aion.Net.TCP_Listener
Aion.Net.TCP_Stream
Aion.Net.UDP
```

### Async Synchronization

```text
Aion.Sync
Aion.Sync.Mutex
Aion.Sync.Semaphore
Aion.Sync.Event
Aion.Sync.Condvar
Aion.Sync.Barrier
Aion.Sync.RWLock
Aion.Sync.Once
```

### Channels, Streams, Actors

```text
Aion.Channel
Aion.Channel.Bounded
Aion.Channel.Unbounded
Aion.Channel.Oneshot
Aion.Channel.Broadcast
Aion.Channel.Watch
Aion.Stream
Aion.Actor
Aion.Selector
```

Note: the selector package is named `Aion.Selector`, not `Aion.Select`, because `select` is an Ada reserved word and the compiler will absolutely call security.

### Cancellation and Supervision

```text
Aion.Cancel
Aion.Cancel_Token
Aion.Cancel_Source
Aion.Task_Group
Aion.Join_Set
Aion.Supervisor
Aion.Scope
Aion.Retry
```

### Observability

```text
Aion.Metrics
Aion.Tracing
Aion.Diagnostics
Aion.Test_Support
Aion.Benchmark_Support
```

---

## Installation

### Prerequisites

Install:

- Alire
- GNAT
- GPRbuild
- Git
- PowerShell or terminal

Verify:

```powershell
alr --version
alr exec -- gnat --version
alr exec -- gprbuild --version
```

If `gprbuild` is not recognized directly, use:

```powershell
alr exec -- gprbuild
```

Alire manages the compiler environment. Windows PATH will not magically understand your ambitions.

---

## Build Aion

From the Aion root:

```powershell
alr exec -- gprbuild -P aion.gpr
```

Expected output includes:

```text
Build Libraries
[gprlib]       aion.lexch
[archive]      libaion.a
[index]        libaion.a
```

That means Aion is building as a library.

---

## Build Examples

```powershell
alr exec -- gprbuild -P aion_examples.gpr
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

## Build Tests

```powershell
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
```

---

## Build Benchmarks

```powershell
alr exec -- gprbuild -P aion_benchmarks.gpr
```

Run:

```powershell
.\bin\bench_scheduler.exe
.\bin\bench_spawn.exe
.\bin\bench_timers.exe
.\bin\bench_channels.exe
.\bin\bench_cancellation.exe
.\bin\bench_reactor.exe
.\bin\bench_tcp_echo.exe
```

---

## Using Aion as a Library

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

Build and run:

```powershell
alr build
alr run
```

Expected output:

```text
Using Aion
Aion is a structured asynchronous runtime and scheduler foundation for Ada.
Aion runtime created successfully.
Runtime shut down successfully.
```

---

## Quick Start

Minimal runtime program:

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

   Ada.Text_IO.Put_Line ("Running " & Aion.Name);

   Shutdown_Result := Aion.Runtime.Shutdown (Runtime);

   if Aion.Runtime.Operation_Results.Is_Ok (Shutdown_Result) then
      Ada.Text_IO.Put_Line ("Shutdown complete.");
   else
      Ada.Text_IO.Put_Line
        ("Shutdown failed: "
         & Aion.Errors.Image
             (Aion.Runtime.Operation_Results.Error (Shutdown_Result)));
   end if;
end Main;
```

Ada will not let you ignore function results. This is annoying, but so is debugging silent shutdown failures at 2 AM.

---

## Runtime Job Example

Create a package-level job.

`demo_jobs.ads`

```ada
package Demo_Jobs is
   procedure Print_Message;
end Demo_Jobs;
```

`demo_jobs.adb`

```ada
with Ada.Text_IO;

package body Demo_Jobs is
   procedure Print_Message is
   begin
      Ada.Text_IO.Put_Line ("Hello from an Aion runtime job.");
   end Print_Message;
end Demo_Jobs;
```

Main:

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
        Job  => Demo_Jobs.Print_Message'Access);

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

Use package-level procedures for runtime jobs. Deeply nested callbacks and Ada accessibility rules can become a small courtroom drama.

---

## Futures and Promises

Aion futures are generic and typed.

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

Typed futures are more verbose than dynamic payloads, but they let the compiler catch the mess before users do. Minor miracle.

---

## Channels

Aion provides typed channels:

```text
Aion.Channel.Bounded
Aion.Channel.Unbounded
Aion.Channel.Oneshot
Aion.Channel.Broadcast
Aion.Channel.Watch
```

Use bounded channels by default. Backpressure is not optional in serious systems; it is the difference between “busy service” and “memory landfill.”

Example package usage:

```ada
with Aion.Channel.Bounded;
```

Instantiate the generic channel for your message type, then use send/receive APIs from the instantiated package.

---

## Networking

Networking packages:

```ada
with Aion.Net;
with Aion.Net.Address;
with Aion.Net.TCP;
with Aion.Net.TCP_Listener;
with Aion.Net.TCP_Stream;
with Aion.Net.UDP;
```

Build examples:

```powershell
alr exec -- gprbuild -P aion_examples.gpr
```

Run echo server in terminal 1:

```powershell
.\bin\echo_server.exe
```

Run echo client in terminal 2:

```powershell
.\bin\echo_client.exe
```

Do not run the server and client sequentially in one terminal unless the server stays alive. Networking remains annoyingly committed to time and causality.

---

## Observability

Aion provides:

```text
Aion.Metrics
Aion.Tracing
Aion.Diagnostics
Aion.Test_Support
Aion.Benchmark_Support
```

These packages expose runtime visibility, tracing helpers, diagnostics summaries, deterministic test utilities, and benchmark support.

Run:

```powershell
.\bin\observability_demo.exe
.\bin\release_diagnostics_demo.exe
```

A runtime that cannot explain itself is not production-ready. It is just quiet and suspicious.

---

## Repository Layout

```text
aion/
├── alire.toml
├── aion.gpr
├── aion_tests.gpr
├── aion_examples.gpr
├── aion_benchmarks.gpr
├── README.md
├── LICENSE
├── CHANGELOG.md
├── docs/
│   ├── architecture.md
│   ├── Usage-Guide.md
│   ├── Installation.md
│   ├── Example-Usage.md
│   ├── Project-Details.md
│   ├── runtime-model.md
│   ├── scheduler.md
│   ├── timers.md
│   ├── networking.md
│   ├── channels.md
│   ├── structured-concurrency.md
│   ├── cancellation.md
│   ├── observability.md
│   ├── benchmarking.md
│   └── release-process.md
├── src/
│   └── Aion library packages
├── tests/
│   └── test runner and module tests
├── examples/
│   └── runnable examples
├── benchmarks/
│   └── benchmark programs
└── tools/
    └── release and validation helpers
```

---

## Testing Strategy

Aion is tested across the runtime layers:

| Area | Coverage |
|---|---|
| Core | version, config, errors, result model |
| Runtime | lifecycle, spawn, shutdown, task handles |
| Scheduler | basic queueing, fairness, stress |
| Futures | promise completion, await, cancellation, timeout |
| Timers | sleep, interval, deadline, fake clock, stress |
| Reactor | resource registration, readiness, shutdown, backend stats |
| Networking | TCP listener/client, echo path, UDP, timeouts |
| Sync | mutex, semaphore, event, condvar, barrier, RWLock, once |
| Channels | bounded, unbounded, oneshot, broadcast, watch, stress |
| Concurrency | cancellation, task groups, join sets, supervisors |
| Observability | metrics, tracing, diagnostics, release integrity |

Run:

```powershell
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
```

---

## Benchmarks

Aion includes benchmarks for:

```text
bench_scheduler
bench_spawn
bench_timers
bench_channels
bench_tcp_echo
bench_cancellation
bench_reactor
```

Run:

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

Example output:

```text
scheduler_stats_snapshot: operations=100000, elapsed_ms=22, ops_per_sec=4.54545454545455E+06
queue_capacity= 16384
```

Benchmark results depend on machine, compiler, flags, and backend. Shocking, yes, computers remain physical objects.

---

## Documentation

Project documentation:

```text
docs/architecture.md
docs/Usage-Guide.md
docs/Installation.md
docs/Example-Usage.md
docs/Project-Details.md
docs/runtime-model.md
docs/scheduler.md
docs/timers.md
docs/networking.md
docs/channels.md
docs/structured-concurrency.md
docs/cancellation.md
docs/observability.md
docs/benchmarking.md
docs/release-process.md
```

Recommended reading order:

```text
Installation.md
Usage-Guide.md
Example-Usage.md
architecture.md
Project-Details.md
```

---

## Packaging

Aion is packaged as an Ada library using Alire and GPRbuild.

Library project:

```text
aion.gpr
```

Build:

```powershell
alr exec -- gprbuild -P aion.gpr
```

Use locally from another project:

```powershell
alr with aion --use F:\Projects-INT\Aion
```

Future public usage after publishing to Alire:

```powershell
alr with aion
```

---

## Security and Reliability Notes

Aion is a local runtime library. It does not require:

- cloud services
- accounts
- telemetry
- remote execution
- background uploads

Reliability goals:

- explicit lifecycle ownership
- no hidden background loops
- no ignored function results
- no silent task failure
- deterministic shutdown behavior
- observable runtime state
- structured cancellation
- stable package boundaries

This is the kind of boring that keeps systems alive. Exciting infrastructure is usually a postmortem draft.

---

## Research Motivation

Aion is motivated by a practical systems question:

> **How can Ada support modern async runtime patterns while preserving its reliability-oriented language model?**

Modern async ecosystems provide strong ergonomics, but they often rely on language-specific abstractions, hidden executors, dynamic task graphs, or runtime behavior that is difficult to inspect.

Ada offers a different foundation:

- strong static typing
- protected objects
- tasking
- explicit package boundaries
- deterministic compilation
- safety-oriented compiler checks
- controlled access semantics

Aion studies how these strengths can support:

- structured task scheduling
- typed futures
- explicit cancellation
- runtime-owned timers and reactors
- safe shutdown
- observable async execution
- platform-aware I/O abstractions
- deterministic tests and benchmarks

Aion is both a practical library and a research-style exploration of async systems design in Ada.

---

## Current Status

Aion currently builds as a reusable Ada library and has been validated from a separate consumer project.

Confirmed consumer usage:

```powershell
alr with aion --use F:\Projects-INT\Aion
alr build
alr run
```

Confirmed output:

```text
Using Aion
Aion is a structured asynchronous runtime and scheduler foundation for Ada.
Aion runtime created successfully.
Runtime shut down successfully.
```

That means Aion is not just a folder full of ambitious `.adb` files. It is usable as a library. Small but dignified victory.

---

## Roadmap

### Runtime

- priority scheduling
- cooperative task budgets
- blocking task pool
- richer task tracing
- runtime-local context

### Futures

- map/then combinators
- richer await helpers
- cancellation-aware future composition
- heterogeneous selector utilities

### Reactor

- Windows IOCP backend
- Linux epoll backend
- macOS/BSD kqueue backend
- backend-specific readiness policies
- edge-triggered and level-triggered options

### Networking

- DNS helpers
- TLS integration strategy
- connection pooling
- long-running accept loops
- graceful listener shutdown
- richer socket diagnostics

### Channels and Actors

- channel-level metrics
- fan-in/fan-out helpers
- mailbox policies
- stream adapters
- backpressure diagnostics

### Observability

- JSON diagnostics output
- structured trace export
- Prometheus-style metrics text
- benchmark comparison reports
- generated release summary

### Packaging

- Alire publication
- generated API documentation
- signed release artifacts
- CI release validation
- example consumer templates

---

## Contributing

Contributions are welcome in areas that improve correctness, clarity, portability, documentation, and runtime behavior.

Good contribution areas:

- scheduler tests
- native reactor backends
- timer accuracy improvements
- future combinators
- channel benchmarks
- networking examples
- diagnostics output
- documentation polish
- Windows/Linux/macOS portability checks
- Alire packaging improvements

Suggested workflow:

1. Fork the repository.
2. Create a focused feature branch.
3. Keep changes modular.
4. Add or update tests.
5. Build the library.
6. Build examples.
7. Run tests.
8. Run relevant benchmarks.
9. Open a pull request with a clear explanation.

Before submitting:

```powershell
alr exec -- gprbuild -P aion.gpr
alr exec -- gprbuild -P aion_examples.gpr
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
alr exec -- gprbuild -P aion_benchmarks.gpr
```

If the change adds warnings, it should have a very good reason. “The compiler started it” is emotionally valid but technically insufficient.

---

## Authors

**Mahesh Chandra Teja Garnepudi**  
**Sagarika Srivastava**

Built at **Kairais Tech**

---

## About Kairais Tech

**Kairais Tech** builds practical, local-first systems with clear trust boundaries, polished interfaces, and explainable behavior.

Website:

```text
https://www.kairais.com
```

Aion follows the same engineering direction as projects such as **Vyre**, **VeriFrame**, **Tempo**, **VeriCent**, **Nodus**, and **ZeroTrace**:

- local ownership
- clear architecture
- inspectable behavior
- practical engineering
- strong documentation
- products that respect the user’s machine instead of treating it like a thin client for someone else’s cloud bill

---

## License

Aion is released under the **MIT License** unless otherwise specified.

Third-party dependencies are licensed under their respective terms.

---

## Closing Note

Aion is built around a simple belief:

> **Async systems should be structured, observable, cancellation-safe, and honest about their runtime behavior.**

Ada already gives developers a serious foundation. Aion adds the async runtime layer that makes that foundation feel modern.

**Aion** — structured time, scheduled cleanly.
