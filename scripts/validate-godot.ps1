param(
    [string]$GodotPath = "",
    [switch]$ShowCommandOnly
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ProjectFile = Join-Path $ProjectRoot "project.godot"

if (-not (Test-Path -LiteralPath $ProjectFile)) {
    throw "project.godot was not found at $ProjectFile"
}

function Resolve-Godot {
    param([string]$ExplicitPath)

    if ($ExplicitPath) {
        if (-not (Test-Path -LiteralPath $ExplicitPath)) {
            throw "Godot executable was not found at $ExplicitPath"
        }

        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }

    $ConfiguredGodot = $env:GODOT_EXE
    if (-not $ConfiguredGodot) {
        $ConfiguredGodot = [Environment]::GetEnvironmentVariable("GODOT_EXE", "User")
    }

    if ($ConfiguredGodot) {
        if (-not (Test-Path -LiteralPath $ConfiguredGodot)) {
            throw "GODOT_EXE is set but Godot was not found at $ConfiguredGodot"
        }

        return (Resolve-Path -LiteralPath $ConfiguredGodot).Path
    }

    foreach ($CommandName in @("godot", "godot4", "Godot")) {
        $Command = Get-Command $CommandName -ErrorAction SilentlyContinue
        if ($Command) {
            return $Command.Source
        }
    }

    $LocalCandidates = @(
        (Join-Path $ProjectRoot "Godot.exe"),
        (Join-Path $ProjectRoot "tools\Godot.exe")
    )

    foreach ($Candidate in $LocalCandidates) {
        if (Test-Path -LiteralPath $Candidate) {
            return (Resolve-Path -LiteralPath $Candidate).Path
        }
    }

    throw "Godot was not found. Install Godot or rerun with -GodotPath."
}

$Godot = Resolve-Godot -ExplicitPath $GodotPath
$ValidationDir = Join-Path $ProjectRoot ".godot\codex_validation"
$ValidationLog = Join-Path $ValidationDir "godot-validation.log"
New-Item -ItemType Directory -Path $ValidationDir -Force | Out-Null

$ResolvedValidationDir = (Resolve-Path -LiteralPath $ValidationDir).Path
$ResolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not $ResolvedValidationDir.StartsWith($ResolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Validation log directory resolved outside the project: $ResolvedValidationDir"
}

$GodotArgs = @(
    "--headless",
    "--disable-crash-handler",
    "--log-file", $ValidationLog,
    "--path", $ProjectRoot,
    "--quit-after", "2"
)

Write-Host "Using Godot: $Godot"
Write-Host "Validating project: $ProjectRoot"
Write-Host "Godot log: $ValidationLog"

if ($ShowCommandOnly) {
    Write-Host "Command: `"$Godot`" $($GodotArgs -join ' ')"
    return
}

# Keep Godot's validation log inside the ignored project-local .godot folder.
# The executable itself may still live outside the workspace, but the script does
# not intentionally write validation output to global Godot user-data folders.
$Output = & $Godot @GodotArgs 2>&1
$ExitCode = $LASTEXITCODE
$Output | ForEach-Object { Write-Host $_ }

if ($null -ne $ExitCode -and $ExitCode -ne 0) {
    throw "Godot validation failed with exit code $ExitCode"
}

if ($Output -match "SCRIPT ERROR|GDScript Error|SHADOWED_|Parse Error|Compile Error") {
    throw "Godot validation reported GDScript errors or warnings."
}

Write-Host "Godot validation completed."
