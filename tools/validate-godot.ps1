param(
    [string]$GodotPath = "",
    [switch]$ShowCommandOnly,
    [switch]$RunSmoke
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

function Read-Log-With-Retry {
    param(
        [string]$Path,
        [string]$ExpectedPattern = "",
        [int]$Attempts = 5
    )

    $LastContent = @()
    for ($Attempt = 0; $Attempt -lt $Attempts; $Attempt += 1) {
        if (Test-Path -LiteralPath $Path) {
            $Content = Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue
            if ($Content) {
                $LastContent = $Content
                if ($ExpectedPattern -eq "" -or (($Content -join "`n") -match $ExpectedPattern)) {
                    return $Content
                }
            }
        }

        Start-Sleep -Milliseconds 250
    }

    return $LastContent
}

$Godot = Resolve-Godot -ExplicitPath $GodotPath
$ValidationDir = Join-Path $ProjectRoot ".godot\codex_validation"
$ValidationLog = Join-Path $ValidationDir "godot-validation.log"
$SmokeLog = Join-Path $ValidationDir "stability-smoke.log"
New-Item -ItemType Directory -Path $ValidationDir -Force | Out-Null

$ResolvedValidationDir = (Resolve-Path -LiteralPath $ValidationDir).Path
$ResolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not $ResolvedValidationDir.StartsWith($ResolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Validation log directory resolved outside the project: $ResolvedValidationDir"
}

$ValidationArgs = @(
    "--headless",
    "--recovery-mode",
    "--disable-crash-handler",
    "--single-threaded-scene",
    "--log-file", $ValidationLog,
    "--path", $ProjectRoot,
    "--quit-after", "2"
)

$SmokeArgs = @(
    "--headless",
    "--disable-crash-handler",
    "--single-threaded-scene",
    "--log-file", $SmokeLog,
    "--path", $ProjectRoot,
    "--script", "res://tests/stability_smoke.gd"
)

Write-Host "Using Godot: $Godot"
Write-Host "Validating project: $ProjectRoot"
Write-Host "Godot log: $ValidationLog"
if ($RunSmoke) {
    Write-Host "Smoke log: $SmokeLog"
}

if ($ShowCommandOnly) {
    Write-Host "Validation command: `"$Godot`" $($ValidationArgs -join ' ')"
    if ($RunSmoke) {
        Write-Host "Smoke command: `"$Godot`" $($SmokeArgs -join ' ')"
    }
    return
}

# Keep Godot's validation log inside the ignored project-local .godot folder.
# The executable itself may still live outside the workspace, but the script does
# not intentionally write validation output to global Godot user-data folders.
Remove-Item -LiteralPath $ValidationLog -Force -ErrorAction SilentlyContinue
$Output = & $Godot @ValidationArgs 2>&1
$ExitCode = $LASTEXITCODE
$LogOutput = @()
$LogOutput = Read-Log-With-Retry -Path $ValidationLog

$CombinedOutput = @($Output) + @($LogOutput)
$CombinedOutput | ForEach-Object { Write-Host $_ }
$OutputText = $CombinedOutput -join "`n"

if ($null -ne $ExitCode -and $ExitCode -ne 0) {
    throw "Godot validation failed with exit code $ExitCode"
}

if ($OutputText -match "SCRIPT ERROR|GDScript Error|SHADOWED_|Parse Error|Compile Error") {
    throw "Godot validation reported GDScript errors or warnings."
}

Write-Host "Godot validation completed."

if (-not $RunSmoke) {
    return
}

Write-Host "Running stability smoke."
Remove-Item -LiteralPath $SmokeLog -Force -ErrorAction SilentlyContinue
$SmokeOutput = & $Godot @SmokeArgs 2>&1
$SmokeExitCode = $LASTEXITCODE
$SmokeLogOutput = @()
$SmokeLogOutput = Read-Log-With-Retry -Path $SmokeLog -ExpectedPattern "STABILITY_SMOKE_OK" -Attempts 24

$CombinedSmokeOutput = @($SmokeOutput) + @($SmokeLogOutput)
$CombinedSmokeOutput | ForEach-Object { Write-Host $_ }
$SmokeOutputText = $CombinedSmokeOutput -join "`n"

if ($null -ne $SmokeExitCode -and $SmokeExitCode -ne 0) {
    throw "Godot stability smoke failed with exit code $SmokeExitCode"
}

if ($SmokeOutputText -match "SCRIPT ERROR|GDScript Error|SHADOWED_|Parse Error|Compile Error") {
    throw "Godot stability smoke reported GDScript errors or warnings."
}

if ($SmokeOutputText -notmatch "STABILITY_SMOKE_OK") {
    throw "Godot stability smoke did not report STABILITY_SMOKE_OK."
}

Write-Host "Godot stability smoke completed."
