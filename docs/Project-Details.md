# Aion Project Details

## Project Name

**Aion**

## Tagline

**Structured asynchronous runtime for Ada.**

## Longer Positioning

Aion is a modular async runtime for Ada that brings modern runtime concepts such as task scheduling, futures, timers, async I/O readiness, networking, synchronization primitives, channels, structured cancellation, supervision, diagnostics, and benchmarks into an Ada-native package hierarchy.

It is designed for developers who want async systems programming without giving up Ada’s strengths: strong typing, package discipline, deterministic concurrency tools, safety-oriented compiler checks, and explicit lifecycle management.

---

## Purpose

Aion’s purpose is to make Ada feel modern for asynchronous systems work.

Ada already has excellent concurrency primitives. What it lacks, compared with newer ecosystems, is a cohesive async runtime experience similar in spirit to Tokio, but expressed in Ada’s own design language.

Aion fills that space by providing:

- runtime-managed worker execution,
- task handles and lifecycle state,
- typed futures and promises,
- sleep, interval, timeout, and deadline utilities,
- reactor-driven I/O readiness,
- TCP and UDP networking APIs,
- async-aware synchronization primitives,
- typed channels and actor mailboxes,
- cancellation tokens and task groups,
- supervisors and retry hooks,
- diagnostics, tracing, benchmarks, and test utilities.

This is not intended to be a thin wrapper around `delay` and Ada tasks. That would be a brochure, not a runtime.

---

## Project Identity

Aion is part of a broader engineering style focused on local-first, reliability-oriented, production-grade tooling. It shares the same design attitude as serious developer infrastructure projects: clean APIs, inspectable behavior, strong documentation, and a preference for boring correctness over flashy chaos.

The project should look credible to:

- systems programmers,
- Ada developers,
- university reviewers,
- robotics and industrial automation teams,
- networking developers,
- safety-conscious software teams,
- technically literate hiring/admissions reviewers.

The project should not look like a weekend demo that escaped into GitHub unsupervised.

---

## Core Features

### Runtime Core

Aion provides a runtime handle, runtime configuration, worker execution, task spawning, task handles, cooperative yielding, scheduler statistics, and graceful shutdown.

### Scheduler

The scheduler manages queued work and runtime task accounting. It is the execution backbone of the runtime.

### Futures and Promises

Aion provides typed generic futures and promises for async value completion, failure propagation, cancellation, timeout, and blocking bridges.

### Timers

Aion supports sleep, interval/ticker behavior, deadline utilities, timeout wrappers, timer queues, and fake clocks for deterministic tests.

### Reactor

The reactor abstracts readiness-based I/O. It tracks resources, tokens, readiness interests, queued events, and backend statistics.

### Networking

Aion exposes TCP listeners, TCP streams, UDP sockets, address types, socket options, async connect, accept, read, write, timeout, and close operations.

### Synchronization

Aion includes async-aware mutexes, semaphores, events, condition variables, barriers, read/write locks, once cells, and counters.

### Channels and Actors

Aion provides bounded channels, unbounded channels, oneshot channels, broadcast channels, watch channels, streams, actor mailboxes, and selector-style future waiting.

### Structured Concurrency

Aion includes cancellation sources, cancellation tokens, task groups, join sets, scoped tasks, supervisors, retry policies, and shutdown-tree coordination.

### Observability

Aion provides metrics, tracing spans, diagnostics summaries, test support, benchmark helpers, release validation support, and CI-oriented tooling.

---

## Package Overview

```text
Aion
Aion.Types
Aion.Errors
Aion.Config
Aion.Version
Aion.Result
Aion.Internal

Aion.Runtime
Aion.Runtime.Builder
Aion.Scheduler
Aion.Task_Handle
Aion.Task_Id
Aion.Waker
Aion.Yield
Aion.Shutdown

Aion.Future
Aion.Promise
Aion.Awaitable
Aion.Completion
Aion.Poll
Aion.Block_On

Aion.Time
Aion.Sleep
Aion.Timeout
Aion.Interval
Aion.Deadline
Aion.Clock
Aion.Clock_Fake
Aion.Timer_Queue

Aion.Reactor
Aion.Reactor_Backend
Aion.Readiness
Aion.IO_Resource
Aion.IO_Token
Aion.Platform
Aion.Platform.Windows
Aion.Platform.Linux
Aion.Platform.Darwin

Aion.Net
Aion.Net.Address
Aion.Net.Socket_Options
Aion.Net.TCP
Aion.Net.TCP_Listener
Aion.Net.TCP_Stream
Aion.Net.UDP

Aion.Sync
Aion.Sync.Mutex
Aion.Sync.Semaphore
Aion.Sync.Event
Aion.Sync.Condvar
Aion.Sync.Barrier
Aion.Sync.RWLock
Aion.Sync.Once

Aion.Channel
Aion.Channel.Bounded
Aion.Channel.Unbounded
Aion.Channel.Oneshot
Aion.Channel.Broadcast
Aion.Channel.Watch
Aion.Stream
Aion.Actor
Aion.Selector

Aion.Cancel
Aion.Cancel_Token
Aion.Cancel_Source
Aion.Task_Group
Aion.Join_Set
Aion.Supervisor
Aion.Scope
Aion.Retry

Aion.Metrics
Aion.Tracing
Aion.Diagnostics
Aion.Test_Support
Aion.Benchmark_Support
```

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
│   └── Aion packages
├── tests/
│   └── unit and integration tests
├── examples/
│   └── runnable demo applications
├── benchmarks/
│   └── benchmark programs
└── tools/
    └── release and validation scripts
```

---

## Build System

Aion uses:

```text
Alire
GPRbuild
GNAT
Ada 2022 where supported
```

Primary project files:

```text
aion.gpr              Library build
aion_tests.gpr        Test build
aion_examples.gpr     Example build
aion_benchmarks.gpr   Benchmark build
```

Build commands:

```powershell
alr exec -- gprbuild -P aion.gpr
alr exec -- gprbuild -P aion_examples.gpr
alr exec -- gprbuild -P aion_tests.gpr
alr exec -- gprbuild -P aion_benchmarks.gpr
```

---

## Library Usage

Aion is consumed from Ada code with:

```ada
with Aion;
with Aion.Runtime;
with Aion.Config;
```

Not:

```ada
import Aion;
```

This is Ada. It has its own vocabulary, and it will not apologize.

Example consumer command:

```powershell
alr with aion --use F:\Projects-INT\Aion
alr build
alr run
```

---

## Quality Goals

Aion’s engineering quality goals are:

- warning-free builds,
- deterministic tests,
- clear package boundaries,
- typed results,
- explicit shutdown,
- lifecycle-safe runtime handles,
- no hidden background loops,
- no duplicate scheduling systems,
- no swallowed exceptions,
- no ignored function results,
- no casual unbounded queues,
- no undocumented runtime behavior.

The runtime should be boring where reliability matters and expressive where developers need ergonomics.

---

## Current Status

Aion currently builds as a library through `aion.gpr`, and can be consumed from a separate Alire project using a local dependency pin.

Confirmed consumer usage pattern:

```powershell
alr with aion --use F:\Projects-INT\Aion
alr build
alr run
```

Confirmed Ada import pattern:

```ada
with Aion;
with Aion.Config;
with Aion.Runtime;
```

Confirmed basic consumer output:

```text
Using Aion
Aion is a structured asynchronous runtime and scheduler foundation for Ada.
Aion runtime created successfully.
Runtime shut down successfully.
```

This confirms Aion is no longer just a source folder. It is usable as a library. Small miracle, heavily type-checked.

---

## Benchmarks

Current benchmark categories include:

```text
bench_scheduler
bench_spawn
bench_timers
bench_channels
bench_tcp_echo
bench_cancellation
bench_reactor
```

Benchmarks are intended to measure:

- scheduler throughput,
- spawn accounting path,
- timer scheduling,
- bounded channel throughput,
- cancellation source creation/cancel path,
- reactor stats snapshot,
- TCP address preparation.

These benchmarks are development indicators, not absolute performance guarantees. Hardware, compiler version, optimization flags, and backend implementation all matter.

---

## Examples

Example applications include:

```text
aion_module1_app
config_validation_demo
runtime_core_demo
scheduler_demo
future_promise_demo
runtime_future_demo
timer_demo
timeout_demo
interval_demo
reactor_demo
reactor_backend_demo
echo_server
echo_client
tcp_timeout_demo
udp_ping_pong
sync_primitives_demo
channel_demo
actor_mailbox_demo
select_demo
cancellation_demo
task_group_demo
supervisor_demo
observability_demo
release_diagnostics_demo
```

These examples demonstrate the public API surface and act as sanity checks for real consumer usage.

---

## Testing

The test suite covers the major modules:

- core foundation,
- runtime lifecycle,
- scheduler behavior,
- futures and promises,
- timers,
- reactor,
- networking,
- synchronization,
- channels,
- structured concurrency,
- observability,
- release integrity.

Run:

```powershell
alr exec -- gprbuild -P aion_tests.gpr
.\bin\test_runner.exe
```

---

## Documentation Goals

Aion documentation should help three audiences:

### New Ada users

They need clear installation steps, import syntax, examples, and common errors.

### Systems programmers

They need architecture, lifecycle, scheduler behavior, cancellation semantics, and performance information.

### Reviewers and maintainers

They need project goals, package structure, quality standards, release process, and maturity notes.

Good documentation is not decoration. It is part of the system. Bad documentation is just a treasure map drawn by someone who hates treasure.

---

## Roadmap

Recommended future improvements:

### Runtime

- priority scheduling,
- cooperative task budgets,
- blocking task pool,
- runtime-local context,
- richer task naming and tracing.

### Reactor

- native Windows IOCP backend,
- Linux epoll backend,
- macOS/BSD kqueue backend,
- readiness edge/level-triggered policy controls.

### Networking

- TLS integration strategy,
- DNS utilities,
- connection pooling,
- server accept loops,
- graceful listener shutdown.

### Futures

- combinators,
- map/and_then style helpers,
- select across heterogeneous results,
- cancellation-aware await helpers.

### Channels

- metrics per channel,
- async stream adapters,
- fan-in/fan-out utilities,
- bounded mailbox policies.

### Observability

- JSON diagnostics output,
- structured trace export,
- Prometheus-style metrics output,
- benchmark comparison reports.

### Packaging

- publish to Alire index,
- release archives,
- generated API docs,
- CI artifact validation.

---

## Project Summary

Aion is an ambitious Ada runtime project with a clear goal:

> Bring modern async runtime ergonomics to Ada while preserving Ada’s reliability, explicitness, and safety-oriented design.

It should feel modern without becoming fashionable nonsense. It should be practical without becoming sloppy. It should be powerful without becoming magical.

That is the line Aion walks.
