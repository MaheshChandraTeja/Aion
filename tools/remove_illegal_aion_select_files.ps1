param(
    [string]$ProjectRoot = (Get-Location).Path
)

$files = @(
    Join-Path $ProjectRoot "src\aion-select.ads",
    Join-Path $ProjectRoot "src\aion-select.adb"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "Removed illegal Ada reserved-word unit: $file"
    }
}
