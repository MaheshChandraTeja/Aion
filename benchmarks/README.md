# Benchmarks

Module 2 includes an initial scheduler benchmark skeleton.

`bench_scheduler.adb` spawns many small runtime jobs and measures wall-clock completion time.

Note: the benchmark uses GNAT's `Unrestricted_Access` for a local benchmark job to keep the benchmark self-contained. Production Aion users should prefer library-level job procedures.
