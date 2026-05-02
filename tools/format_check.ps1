$ErrorActionPreference = "Stop"

$files = Get-ChildItem -Recurse -Include *.adb,*.ads | Where-Object {
  $_.FullName -notmatch "\\obj\\" -and $_.FullName -notmatch "\\lib\\" -and $_.FullName -notmatch "\\bin\\"
}

foreach ($file in $files) {
  $content = Get-Content $file.FullName -Raw
  if ($content -match "\t") {
    throw "Tab character found in $($file.FullName). Use spaces. Ada is old enough; don't add tabs to its suffering."
  }
  if (-not $content.EndsWith("`n")) {
    throw "Missing final newline in $($file.FullName)"
  }
}

Write-Host "Format check passed."
