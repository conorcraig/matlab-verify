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
# git diff --quiet exits 1 when the tree is dirty; that is an answer, not a failure.
if (Test-Path variable:PSNativeCommandUseErrorActionPreference) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Find-ConfigRoot([string]$Start) {
    $dir = [IO.Path]::GetFullPath($Start)
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $dir 'config\verify.json')) { return $dir }
        $parent = Split-Path -Parent $dir
        if (-not $parent -or $parent -eq $dir) {
            throw "No config/verify.json found at or above $Start."
        }
        $dir = $parent
    }
}

function Resolve-StartPath([string]$Start, [string]$Path) {
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return [IO.Path]::GetFullPath((Join-Path $Start $Path))
}

function ConvertTo-RootRelative([string]$Root, [string]$Path) {
    $rel = [IO.Path]::GetRelativePath([IO.Path]::GetFullPath($Root), [IO.Path]::GetFullPath($Path))
    return ($rel -replace '\\', '/')
}

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$ArgumentList)
    # Named -ArgumentList so tokens like --quiet are not bound as parameters.
    $out = & git @ArgumentList 2>&1
    $lines = @($out | ForEach-Object { "$_" } | Where-Object { $_ -ne '' })
    return [pscustomobject]@{ Exit = $LASTEXITCODE; Lines = $lines }
}

function Get-BaseRef([string]$Root) {
    $sym = Invoke-Git -ArgumentList @('-C', $Root, 'symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD')
    if ($sym.Exit -eq 0 -and $sym.Lines.Count -gt 0) { return $sym.Lines[0].Trim() }
    foreach ($candidate in @('origin/main', 'origin/master', 'main', 'master')) {
        $ver = Invoke-Git -ArgumentList @('-C', $Root, 'rev-parse', '--verify', '--quiet', $candidate)
        if ($ver.Exit -eq 0) { return $candidate }
    }
    throw 'No base branch (origin/HEAD, main, or master).'
}

function Get-GitMatlabFiles([string]$Root, [string[]]$DiffArgs) {
    $top = Invoke-Git -ArgumentList @('-C', $Root, 'rev-parse', '--show-toplevel')
    if ($top.Exit -ne 0) { throw "git rev-parse failed: $($top.Lines -join ' ')" }
    $gitRoot = $top.Lines[0].Trim()
    $diff = Invoke-Git -ArgumentList (@('-C', $gitRoot) + $DiffArgs)
    if ($diff.Exit -ne 0) { throw "git diff failed ($($diff.Exit)): $($diff.Lines -join ' ')" }
    $found = [System.Collections.Generic.List[string]]::new()
    foreach ($rel in $diff.Lines) {
        $rel = ($rel.Trim() -replace '\\', '/')
        if ($rel -notmatch '\.m$') { continue }
        $abs = Join-Path $gitRoot ($rel -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $abs)) { continue }
        $found.Add((ConvertTo-RootRelative $Root $abs))
    }
    return $found
}

$toolRoot = Split-Path $PSScriptRoot -Parent
$startDir = (Get-Location).Path
$root = Find-ConfigRoot $startDir
Import-Module (Join-Path $PSScriptRoot 'Baseline.psm1') -Force

$Target = @($Target | ForEach-Object { $_ -split '\s+' } | Where-Object { $_ })
$matlabNames = @($MatlabChecks -split '\s+' | Where-Object { $_ })
$externalNames = @($ExternalChecks -split '\s+' | Where-Object { $_ })
if ($Target.Count) {
    $fileKind = 'explicit paths'
    $files = @($Target | ForEach-Object { ConvertTo-RootRelative $root (Resolve-StartPath $startDir $_) })
}
else {
    $worktree = Invoke-Git -ArgumentList @('-C', $root, 'diff', '--quiet', 'HEAD')
    if ($worktree.Exit -eq 1) {
        $fileKind = 'working tree (staged and unstaged)'
        $files = @(Get-GitMatlabFiles $root @('diff', '--name-only', '--diff-filter=ACMR', 'HEAD'))
    }
    elseif ($worktree.Exit -eq 0) {
        $base = Get-BaseRef $root
        $fileKind = "branch vs base ($base)"
        $baseCommit = Invoke-Git -ArgumentList @('-C', $root, 'merge-base', 'HEAD', $base)
        if ($baseCommit.Exit -ne 0) { throw "git merge-base failed: $($baseCommit.Lines -join ' ')" }
        $files = @(Get-GitMatlabFiles $root @('diff', '--name-only', '--diff-filter=ACMR', $baseCommit.Lines[0].Trim(), 'HEAD'))
    }
    else { throw "git diff --quiet failed ($($worktree.Exit)): $($worktree.Lines -join ' ')" }
}
Set-Location $root

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
$shown = if ($files.Count) { $files -join ' ' } else { '(none)' }
Out-Line "verify: file set: $fileKind" -Always
Out-Line "verify: files: $shown" -Always
Out-Line "verify: report $(Resolve-Path -Relative $reportDir)"

foreach ($name in $externalNames) {
    if (-not $files.Count) {
        Out-Line ('-- {0,-11} skipped (no files)' -f $name)
        continue
    }
    $t = [Diagnostics.Stopwatch]::StartNew()
    $found = @(& (Join-Path $PSScriptRoot "checks/$name.ps1") @files)
    $lines = @(Invoke-Baseline -Check $name -Issues $found -Root $root -Update:$Update)
    foreach ($l in $lines) { if ($l -match $IssuePattern) { $issues.Add($l) }; Out-Line $l }
    Out-Line ('-- {0,-11} {1,3} issue(s), {2,5:N1}s' -f $name, @($lines | Where-Object { $_ -match $IssuePattern }).Count, $t.Elapsed.TotalSeconds)
}

$quote = { param($items) '{' + (($items | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ',') + '}' }
$mode = if ($Update) { 'update' } else { 'check' }
$verbose = if ($Quiet) { 'false' } else { 'true' }
$fileExpr = if ($files.Count) { & $quote $files } else { 'strings(0,1)' }
$matlabDir = ((Join-Path $toolRoot 'matlab') -replace '\\', '/')
$call = "addpath('$($matlabDir -replace "'", "''")'); verify.run($(& $quote $matlabNames), " +
        "$fileExpr, 'Mode', '$mode', 'Verbose', $verbose);"
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
