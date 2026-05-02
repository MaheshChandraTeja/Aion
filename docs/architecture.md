# Aion Architecture

> **Aion is a structured asynchronous runtime for Ada, built for reliable networking, deterministic concurrency, cancellation-safe tasks, and production-grade systems software.**

Aion exists because Ada already has excellent concurrency primitives, but modern async application development needs a higher-level runtime model: task spawning, scheduling, futures, timers, cancellation, channels, networking, observability, and deterministic testing. Aion is designed to provide that layer without pretending Ada is Rust, Go, JavaScript, or whatever language the internet is emotionally attached to this week.

Aion’s architecture is intentionally modular. Each subsystem owns one responsibility, exposes a clear package boundary, and reuses shared primitives from earlier modules. The goal is not merely to make examples compile. The goal is to create a runtime foundation that can grow into serious systems software: network services, robotics tooling, industrial automation, telemetry pipelines, embedded Linux agents, developer infrastructure, simulations, and high-reliability applications.

---

## 1. Design Philosophy

Aion follows four core architectural principles.

### 1.1 Ada-native, not Rust cosplay

Ada already has tasks, protected objects, strong typing, access safety, deterministic package boundaries, and compiler-enforced rules that catch entire species of runtime bugs before they hatch. Aion builds on those strengths instead of fighting them.

The runtime does not try to recreate Tokio line-for-line. That would be architectural karaoke. Aion borrows the useful ideas: runtime-managed work, structured cancellation, async I/O readiness, futures, timers, channels, and observability. Then it expresses them through Ada packages, records, protected objects, generic units, and explicit result handling.

### 1.2 One runtime, one scheduler, no hidden circus

All async behavior flows through the runtime and scheduler. Timers, networking, futures, task groups, channels, and supervision must reuse the same lifecycle model. No subsystem is allowed to quietly create its own unmanaged worker loop unless it is explicitly owned by the runtime.

This prevents a common failure mode in async systems: every feature starts innocent, then somehow the project has five event loops, three background threads, two shutdown paths, and one developer whispering apologies into a terminal.

### 1.3 Structured failure instead of swallowed exceptions

Aion treats failures as first-class runtime events. Operations return typed result objects where appropriate. Task handles expose completion state. Supervisors apply restart policies. Shutdown can propagate cancellation. Runtime statistics expose failed, completed, and active task counts.

The design goal is simple: no task should fail silently. Silent failure is just technical debt wearing camouflage.

### 1.4 Deterministic testing and observability

A serious runtime must be testable. Aion provides fake clocks, test support helpers, metrics snapshots, tracing spans, diagnostics reports, and benchmark helpers. This makes the runtime inspectable during development and safer in production.

If a runtime cannot explain what it is doing, it is not production-grade. It is just fast until it is embarrassing.

---

## 2. High-Level System View

Aion is organized as layered packages. Each layer depends only on the layers beneath it.

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

The lower layers provide stable primitives. The upper layers combine those primitives into ergonomic developer-facing features.

---

## 3. Module Breakdown

### Module 1: Core Foundation and Public API

Packages:

```text
Aion
Aion.Types
Aion.Errors
Aion.Config
Aion.Version
Aion.Result
Aion.Internal
```

This layer defines shared runtime vocabulary: task identifiers, timeout values, error records, configuration, version metadata, and generic result handling.

Everything else depends on this layer. If a later module invents another timeout type, another task state enum, or another error model, that module has betrayed the architecture and should be stared at sternly.

---

### Module 2: Runtime Core and Scheduler

Packages:

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

The runtime owns the worker task lifecycle, scheduling queue, spawned jobs, task accounting, cooperative yielding, graceful shutdown, and runtime statistics.

The scheduler is intentionally explicit. Work is submitted as jobs, tracked through task handles, and executed by runtime-managed workers. Aion’s runtime is the central authority for task execution, which keeps later systems like timers, channels, networking, and cancellation from becoming independent little kingdoms.

---

### Module 3: Future, Promise, and Awaitable Model

Packages:

```text
Aion.Future
Aion.Promise
Aion.Awaitable
Aion.Completion
Aion.Poll
Aion.Block_On
```

This module provides typed future/promise primitives. Ada does not have a language-native `Future` trait like Rust, so Aion implements futures as generic packages. This keeps values strongly typed and avoids the dreaded “universal payload” anti-pattern.

A future can represent:

- pending work,
- successful completion,
- failure,
- cancellation,
- timeout.

A promise completes a future. Awaiting blocks in a controlled way or polls cooperatively depending on API use. The design is intentionally simple, predictable, and compatible with the runtime.

---

### Module 4: Timers, Sleep, Deadlines, and Clock Abstraction

Packages:

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

Time is a runtime concern. Aion supports sleeps, timeout wrappers, interval/ticker behavior, deadlines, cancellation-aware timer futures, and fake clocks for deterministic tests.

The timer queue is designed as a runtime-owned service. Timers must wake tasks through Aion’s runtime/scheduler path, not through hidden background machinery.

---

### Module 5: Async I/O Reactor

Packages:

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

The reactor is the low-level readiness system. It tracks I/O resources, readiness interests, backend statistics, and wakeups. The current architecture uses a portable backend abstraction with extension points for platform-specific engines:

- Windows: IOCP or Winsock readiness integration,
- Linux: epoll,
- macOS/BSD: kqueue,
- fallback: portable polling/select-style backend.

The public reactor API is backend-stable. Platform-specific improvements should not force user code to change.

---

### Module 6: Async Networking

Packages:

```text
Aion.Net
Aion.Net.Address
Aion.Net.Socket_Options
Aion.Net.TCP
Aion.Net.TCP_Listener
Aion.Net.TCP_Stream
Aion.Net.UDP
```

Networking builds on the reactor, runtime, futures, timers, and timeout model. It exposes TCP listeners, TCP streams, UDP sockets, address parsing, socket options, async connect, accept, read, write, and graceful close flows.

The module is designed so high-level applications do not manually juggle reactor tokens. Users work with networking types while Aion manages readiness internally.

---

### Module 7: Async Synchronization Primitives

Packages:

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

This module provides async-aware coordination primitives. Ada protected objects are excellent, but runtime-aware async applications need primitives that cooperate with scheduling and wakeups.

The primitives provide a foundation for channels, actor mailboxes, structured concurrency, and user applications.

---

### Module 8: Channels, Streams, and Actor Utilities

Packages:

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

Channels provide typed communication between runtime tasks. Aion supports bounded channels, unbounded channels, oneshot channels, broadcast channels, watch channels, stream abstractions, actor mailboxes, and selector-style waiting across multiple futures.

The package is called `Aion.Selector`, not `Aion.Select`, because `select` is an Ada reserved word and Ada will absolutely call the grammar police.

---

### Module 9: Cancellation, Structured Concurrency, and Supervision

Packages:

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

This module prevents the classic async disaster: spawn tasks everywhere and pray.

Aion supports cancellation sources, tokens, task groups, join sets, scoped task ownership, supervisors, restart policies, retry hooks, deadlines, and structured shutdown behavior.

No task should be silently orphaned unless the user explicitly detaches it. Detached tasks are useful, but they should not be accidental. Accidental detached tasks are how production systems become haunted.

---

### Module 10: Observability, Testing, Benchmarks, Packaging, and Documentation

Packages:

```text
Aion.Metrics
Aion.Tracing
Aion.Diagnostics
Aion.Test_Support
Aion.Benchmark_Support
```

This final layer makes the runtime inspectable and packageable. It provides metrics snapshots, tracing spans, diagnostics reports, deterministic test utilities, benchmark helpers, release validation helpers, CI workflows, and documentation.

It is deliberately placed at the end because it collects information from earlier layers rather than controlling them.

---

## 4. Runtime Lifecycle

Aion runtime lifecycle follows this broad sequence:

```text
Create configuration
        ↓
Create runtime
        ↓
Spawn runtime jobs
        ↓
Run / wait / interact
        ↓
Observe stats
        ↓
Shutdown gracefully
        ↓
Inspect shutdown result
```

Example:

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

---

## 5. Error Handling Model

Aion uses structured errors through `Aion.Errors` and generic results through `Aion.Result`.

The preferred pattern is:

```ada
if Some_Result.Is_Ok then
   -- use value
else
   -- inspect structured error
end if;
```

Aion avoids silently ignored results. If a function returns a result, user code should check it. Ada and GNAT will complain when function results are discarded. This is annoying for about five minutes and then becomes one of the reasons the codebase does not quietly rot.

---

## 6. Scheduling Model

The scheduler owns a queue of runtime jobs. Each job has:

- a task identifier,
- a name,
- a procedure access value,
- lifecycle state,
- accounting metadata.

Workers take jobs from the scheduler and execute them. Runtime statistics track queued, active, completed, and failed work.

Aion’s scheduler is intentionally conservative. It favors correctness and clean lifecycle accounting before micro-optimizations. Performance can be improved inside the scheduler without changing public APIs.

---

## 7. Timer and Reactor Ownership

Timers and reactors are runtime-owned services.

This matters because shutdown must coordinate everything:

```text
Runtime shutdown
   ├── stop accepting new work
   ├── cancel or drain timers
   ├── stop reactor events
   ├── wake blocked awaiters
   ├── join worker tasks
   └── report shutdown result
```

Without centralized ownership, shutdown becomes a scavenger hunt. Aion avoids that.

---

## 8. Observability Model

Aion exposes diagnostics through:

```text
Aion.Metrics
Aion.Tracing
Aion.Diagnostics
Aion.Benchmark_Support
```

Metrics should be snapshots, not hidden mutable global state. Diagnostics should summarize runtime configuration, scheduler health, reactor state, timer queue behavior, channel counters, cancellation state, and release/build information.

The goal is that a user can answer:

- How many tasks ran?
- How many failed?
- Is the reactor running?
- How deep is the queue?
- Are timers being scheduled?
- Did cancellation propagate?
- Which subsystem is overloaded?

If the answer is “go read logs and pray,” the architecture has failed.

---

## 9. Extension Points

Aion is designed to grow through stable extension points.

### Platform I/O backends

New backends can be added behind:

```text
Aion.Reactor_Backend
Aion.Platform.*
```

without rewriting networking APIs.

### Future integrations

More future combinators can be added around:

```text
Aion.Future
Aion.Awaitable
Aion.Poll
```

### Runtime policies

The runtime builder can later support:

- worker affinity,
- priority scheduling,
- cooperative budget limits,
- bounded blocking pools,
- configurable panic/failure policy.

### Observability exporters

Metrics and tracing can later integrate with:

- file logging,
- JSON reports,
- Prometheus-style text,
- OpenTelemetry-style spans,
- local diagnostics dashboards.

---

## 10. Current Maturity

Aion currently functions as a modular Ada async runtime foundation with examples, benchmarks, tests, Alire integration, and consumer-project usage.

The current implementation is suitable for experimentation, internal tooling, educational runtime design, and controlled systems projects. Platform-native I/O backends and deeply optimized scheduler internals are natural future expansion areas.

That is not weakness. That is honest architecture. The embarrassing version would pretend everything is production-perfect while quietly using a placeholder backend and a prayer candle.

---

## 11. Architecture Goals

Aion should continue to optimize toward:

- deterministic task lifecycle,
- reliable shutdown,
- typed futures and channels,
- clear runtime ownership,
- cancellation-safe structured concurrency,
- platform-expandable I/O,
- observable internals,
- clean Alire packaging,
- examples that compile,
- warnings kept near zero,
- documentation that tells the truth.

The long-term goal is straightforward:

> Make Ada feel modern for async systems programming without sacrificing the reliability that makes Ada worth using in the first place.
