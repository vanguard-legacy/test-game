param(
    [Parameter(Mandatory = $true)]
    [string]$GodotPath
)

$ErrorActionPreference = "Stop"

$ResolvedGodot = Resolve-Path -LiteralPath $GodotPath -ErrorAction Stop
if (-not (Test-Path -LiteralPath $ResolvedGodot.Path -PathType Leaf)) {
    throw "Godot executable was not found at $GodotPath"
}

$BinDir = Join-Path $env:USERPROFILE "bin"
$ShimPath = Join-Path $BinDir "godot.cmd"
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

[Environment]::SetEnvironmentVariable("GODOT_EXE", $ResolvedGodot.Path, "User")
$env:GODOT_EXE = $ResolvedGodot.Path

$Shim = @'
@echo off
if "%GODOT_EXE%"=="" (
  echo GODOT_EXE is not set. Run scripts\set-godot.ps1 -GodotPath "C:\Path\To\Godot.exe".
  exit /b 1
)
"%GODOT_EXE%" %*
'@
Set-Content -LiteralPath $ShimPath -Value $Shim -Encoding ASCII

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$PathParts = @()
if (-not [string]::IsNullOrWhiteSpace($UserPath)) {
    $PathParts = $UserPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

$HasBinDir = $PathParts | Where-Object { $_.TrimEnd("\") -ieq $BinDir.TrimEnd("\") }
if (-not $HasBinDir) {
    [Environment]::SetEnvironmentVariable("Path", (($PathParts + $BinDir) -join ";"), "User")
}

$SessionHasBinDir = $env:Path -split ";" | Where-Object { $_.TrimEnd("\") -ieq $BinDir.TrimEnd("\") }
if (-not $SessionHasBinDir) {
    $env:Path = (($env:Path -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) + $BinDir) -join ";"
}

Write-Host "GODOT_EXE set to: $($ResolvedGodot.Path)"
Write-Host "Godot shim written to: $ShimPath"
Write-Host "User Path includes: $BinDir"
& godot --version
