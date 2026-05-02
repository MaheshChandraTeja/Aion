$ErrorActionPreference = "Stop"

Write-Host "== Building Aion library =="
alr exec -- gprbuild -P aion.gpr

Write-Host "== Building Aion tests =="
alr exec -- gprbuild -P aion_tests.gpr

Write-Host "== Running Aion tests =="
if (Test-Path ".\bin\test_runner.exe") {
  .\bin\test_runner.exe
} else {
  .\bin\test_runner
}

Write-Host "Aion tests passed. Somehow the machines cooperated."
