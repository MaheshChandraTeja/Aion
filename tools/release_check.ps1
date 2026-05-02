$ErrorActionPreference = "Stop"

Write-Host "== Aion release check =="
.\tools\format_check.ps1
.\tools\test_all.ps1

Write-Host "== Building examples =="
gprbuild -P aion_examples.gpr

Write-Host "== Building benchmarks =="
gprbuild -P aion_benchmarks.gpr

Write-Host "Aion release check passed. Civilization briefly functioned."
