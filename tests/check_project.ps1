param(
    [string]$GodotPath = (Join-Path $env:USERPROFILE 'Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe')
)

$ErrorActionPreference = 'Stop'
$taskProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $taskProjectRoot 'project.godot'))) {
    throw 'project.godot was not found beside the tests directory.'
}
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw 'Pass the installed Godot console executable using -GodotPath.'
}

$taskVersion = & $GodotPath --version
if ($LASTEXITCODE -ne 0 -or $taskVersion -notmatch '^4\.7\.2\.stable\.') {
    throw "Expected Godot 4.7.2 stable. Found: $taskVersion"
}
Write-Output "Godot: $taskVersion"

$taskLogDirectory = Join-Path $taskProjectRoot '.godot\checks'
$taskPreviousAppData = $env:APPDATA
$taskPreviousLocalAppData = $env:LOCALAPPDATA
try {
    # Keep editor settings and test user data inside this project's ignored cache.
    $env:APPDATA = Join-Path $taskProjectRoot '.godot\tooling\AppData\Roaming'
    $env:LOCALAPPDATA = Join-Path $taskProjectRoot '.godot\tooling\AppData\Local'
    New-Item -ItemType Directory -Path $taskLogDirectory,$env:APPDATA,$env:LOCALAPPDATA -Force | Out-Null
    $taskChecks = @(
        @{ Name = 'import'; Arguments = @('--import') },
        @{ Name = 'parse'; Arguments = @('--script', 'res://tests/validate_project.gd', '--check-only') },
        @{ Name = 'layout'; Arguments = @('--script', 'res://tests/validate_project.gd', '--quit-after', '600') },
        @{ Name = 'startup'; Arguments = @('--quit-after', '10') }
    )
    foreach ($taskCheck in $taskChecks) {
        $taskLogPath = Join-Path $taskLogDirectory ($taskCheck.Name + '.log')
        $taskArguments = @('--headless', '--path', $taskProjectRoot, '--log-file', $taskLogPath) + $taskCheck.Arguments
        & $GodotPath @taskArguments
        if ($LASTEXITCODE -ne 0) {
            throw "Godot check failed: $($taskCheck.Name), exit code $LASTEXITCODE"
        }
        if (-not (Test-Path -LiteralPath $taskLogPath)) {
            throw "Missing Godot log: $taskLogPath"
        }
        if (Select-String -LiteralPath $taskLogPath -Pattern '^(SCRIPT ERROR|ERROR|WARNING):' -Quiet) {
            throw "Godot reported a diagnostic. Inspect: $taskLogPath"
        }
        if ($taskCheck.Name -eq 'layout' -and -not (Select-String -LiteralPath $taskLogPath -SimpleMatch 'PASS: project setup, main scene and responsive UI' -Quiet)) {
            throw 'The layout test did not reach its success marker.'
        }
        Write-Output "PASS: $($taskCheck.Name)"
    }
} finally {
    $env:APPDATA = $taskPreviousAppData
    $env:LOCALAPPDATA = $taskPreviousLocalAppData
}
