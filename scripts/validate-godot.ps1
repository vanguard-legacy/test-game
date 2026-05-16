param(
    [string]$GodotPath = ""
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
Write-Host "Using Godot: $Godot"
Write-Host "Validating project: $ProjectRoot"

& $Godot --headless --path $ProjectRoot --quit
$ExitCode = $LASTEXITCODE

if ($null -ne $ExitCode -and $ExitCode -ne 0) {
    throw "Godot validation failed with exit code $ExitCode"
}

Write-Host "Godot validation completed."
