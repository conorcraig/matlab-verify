# Orchestrates one verification run: MATLAB checks in one session plus
# non-MATLAB checks (tools/checks/<name>.ps1), baselines, logs, exit code.
#   -Quiet   agent mode: only issue lines (through summarize.ps1), then summary
#   -Update  ratchet baselines down (never adds entries)
param(
    [string]$MatlabChecks = 'parse lint compat complexity deps tests types naming',
    [string]$ExternalChecks = 'style',
    [string[]]$Target = @(),
    [switch]$Quiet,
    [switch]$Update,
    [string]$Matlab = 'C:\Program Files\MATLAB\R2026b\bin\matlab.exe',
    [int]$KeepReports = 10
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
Import-Module (Join-Path $PSScriptRoot 'Baseline.psm1') -Force

$Target = @($Target | ForEach-Object { $_ -split '\s+' } | Where-Object { $_ })
if (-not $Target) { $Target = @('matlab', 'sample') }
$matlabNames = @($MatlabChecks -split '\s+' | Where-Object { $_ })
$externalNames = @($ExternalChecks -split '\s+' | Where-Object { $_ })

$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss') + 'Z'
$reportDir = Join-Path $root "reports/$stamp"
New-Item -ItemType Directory -Force $reportDir | Out-Null
$env:VERIFY_REPORT_DIR = $reportDir
$log = Join-Path $reportDir 'verify.log'
$clock = [Diagnostics.Stopwatch]::StartNew()

function Out-Line([string]$Line, [switch]$Always) {
    Add-Content -LiteralPath $log -Value $Line
    if ($Always -or -not $Quiet) { Write-Output $Line }
}

$issues = [System.Collections.Generic.List[string]]::new()
Out-Line "verify: target [$($Target -join ' ')], report $(Resolve-Path -Relative $reportDir)"

foreach ($name in $externalNames) {
    $t = [Diagnostics.Stopwatch]::StartNew()
    $found = @(& (Join-Path $PSScriptRoot "checks/$name.ps1") @Target)
    $lines = @(Invoke-Baseline -Check $name -Issues $found -Root $root -Update:$Update)
    foreach ($l in $lines) { if ($l -match $IssuePattern) { $issues.Add($l) }; Out-Line $l }
    Out-Line ('-- {0,-11} {1,3} issue(s), {2,5:N1}s' -f $name, @($lines | Where-Object { $_ -match $IssuePattern }).Count, $t.Elapsed.TotalSeconds)
}

$quote = { param($items) '{' + (($items | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ',') + '}' }
$mode = if ($Update) { 'update' } else { 'check' }
$verbose = if ($Quiet) { 'false' } else { 'true' }
$call = "addpath('$($root -replace "'", "''")/matlab'); verify.run($(& $quote $matlabNames), " +
        "$(& $quote $Target), 'Mode', '$mode', 'Verbose', $verbose);"
$matlabOut = & $Matlab -batch $call 2>&1 | ForEach-Object { "$_" }
$matlabExit = $LASTEXITCODE
$sawSummary = $false
foreach ($l in $matlabOut) {
    if ($l -match $IssuePattern) { $issues.Add($l); Out-Line $l; continue }
    if ($l -match '^verify\(matlab\):') { $sawSummary = $true; Out-Line $l; continue }
    if ($l -match '^(warning: check|baseline )') { Out-Line $l -Always; continue }
    if ($l -match '^\s*$|Trial License|^ERROR: MATLAB error Exit Status') { continue }
    Out-Line $l -Always
}
if (-not $sawSummary) {
    $l = "matlab:0:0: error: [run/matlab] MATLAB exited with code $matlabExit before printing a summary. See $log."
    $issues.Add($l); Out-Line $l
}

$issues | Set-Content (Join-Path $reportDir 'issues.txt')
if ($Quiet -and $issues.Count) {
    $issues | & (Join-Path $PSScriptRoot 'summarize.ps1') | ForEach-Object { Write-Output $_ }
}
$byCheck = ($issues | ForEach-Object { if ($_ -match $IssuePattern) { $Matches.check } } |
    Group-Object | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ' '
$status = if ($issues.Count) { 'FAIL' } else { 'PASS' }
Out-Line ("verify: $status, $($issues.Count) issue(s)" + $(if ($byCheck) { " ($byCheck)" }) +
    (", {0:N1}s, log {1}" -f $clock.Elapsed.TotalSeconds, (Resolve-Path -Relative $log))) -Always

Get-ChildItem (Join-Path $root 'reports') -Directory | Sort-Object Name -Descending |
    Select-Object -Skip $KeepReports | Remove-Item -Recurse -Force
exit $(if ($issues.Count) { 1 } else { 0 })
