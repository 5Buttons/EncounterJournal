# tools/package.ps1 — build the release zip for the 3.3.5a Encounter Journal.
#
# The working directory mixes the shippable addon with dev-only material (NewEra/ source dump,
# References/, daten/ DB2 exports, tools/, *.bak data backups). This script stages ONLY the
# ship list into a folder named `EncounterJournal` (the required install-folder name — all art
# paths resolve under Interface\AddOns\EncounterJournal\) plus the pinned `!!!ClassicAPI`
# dependency, and zips both to dist\EncounterJournal-<version>.zip.
#
#   .\tools\package.ps1                 # addon + !!!ClassicAPI (turnkey install zip)
#   .\tools\package.ps1 -NoClassicAPI   # addon only
#
# Windows PowerShell 5.1 compatible.
param(
  [string]$OutDir,
  [switch]$NoClassicAPI
)
$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not $OutDir) { $OutDir = Join-Path $root "dist" }

# Version from the TOC.
$tocPath = Join-Path $root "EncounterJournal.toc"
$version = "dev"
$m = Select-String -Path $tocPath -Pattern '^## Version:\s*(.+)$' | Select-Object -First 1
if ($m) { $version = $m.Matches[0].Groups[1].Value.Trim() }

# Stage the ship list.
$stage = Join-Path $env:TEMP ("ejpkg-" + [guid]::NewGuid().ToString("N"))
$addonDir = Join-Path $stage "EncounterJournal"
New-Item -ItemType Directory -Force $addonDir | Out-Null

Copy-Item $tocPath                      $addonDir
Copy-Item (Join-Path $root "Bindings.xml") $addonDir
Copy-Item (Join-Path $root "README.md")    $addonDir
Copy-Item (Join-Path $root "Core")             (Join-Path $addonDir "Core") -Recurse
Copy-Item (Join-Path $root "Art")              (Join-Path $addonDir "Art") -Recurse
Copy-Item (Join-Path $root "EncounterJournal") (Join-Path $addonDir "EncounterJournal") -Recurse

# Strip dev leftovers from the stage (backups of the generated data files).
Get-ChildItem $addonDir -Recurse -File -Filter "*.bak" | Remove-Item -Force

if (-not $NoClassicAPI) {
  $capi = Join-Path $root "!!!ClassicAPI"
  if (Test-Path $capi) {
    Copy-Item $capi (Join-Path $stage "!!!ClassicAPI") -Recurse
  } else {
    Write-Warning "!!!ClassicAPI not found at repo root - zip will not be turnkey."
  }
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
$zip = Join-Path $OutDir ("EncounterJournal-" + $version + ".zip")
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip
Remove-Item $stage -Recurse -Force

$size = "{0:N1} MB" -f ((Get-Item $zip).Length / 1MB)
Write-Host "Wrote $zip ($size)"
Write-Host "Install: extract into World of Warcraft\Interface\AddOns\ (both folders)."
