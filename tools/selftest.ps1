# End-to-end self test: every check catches its sample_bad case, baselines
# accept/stale/ratchet correctly, and the default target passes clean.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$verify = Join-Path $PSScriptRoot 'verify.ps1'
$failures = [System.Collections.Generic.List[string]]::new()

function Invoke-Verify([string[]]$VerifyArgs) {
    $out = & pwsh -NoLogo -NoProfile -File $verify @VerifyArgs 2>&1 | ForEach-Object { "$_" }
    [pscustomobject]@{ Exit = $LASTEXITCODE; Out = $out }
}
function Assert([bool]$Condition, [string]$What) {
    if ($Condition) { Write-Output "ok    $What" } else { Write-Output "FAIL  $What"; $failures.Add($What) }
}

Write-Output '== sample_bad: each check catches its case'
$bad = Invoke-Verify @('-Target', 'sample_bad', '-Quiet')
Assert ($bad.Exit -eq 1) 'sample_bad exits 1'
$expected = [ordered]@{
    'parse/*'                 = 'sample_bad/parse/brokenSyntax.m'
    'lint/FCNIL'              = 'sample_bad/lint/oversizedReport.m'
    'lint/FCNOL'              = 'sample_bad/lint/oversizedReport.m'
    'lint/FCNLL'              = 'sample_bad/lint/oversizedReport.m'
    'lint/MNCSN'              = 'sample_bad/lint/oversizedReport.m'
    'lint/LLMNC'              = 'sample_bad/lint/oversizedReport.m'
    'compat/compatR2024b'     = 'sample_bad/compat/usesNewerFunctions.m'
    'compat/compatR2026a'     = 'sample_bad/compat/usesNewerFunctions.m'
    'complexity/CABE'         = 'sample_bad/complexity/classifyReading.m'
    'deps/cycle'              = 'sample_bad/deps/cycleFirst.m'
    'deps/unresolved'         = 'sample_bad/deps/callsMissingHelper.m'
    'deps/product'            = 'sample_bad/deps/usesCoderProduct.m'
    'style/whitespace_assignment' = 'sample_bad/style/badlySpaced.m'
    'tests/failed'            = 'sample_bad/tests/FailingTest.m'
}
foreach ($tag in $expected.Keys) {
    $file = $expected[$tag]
    $hit = $bad.Out | Where-Object { $_.StartsWith("${file}:") -and $_ -like "*: ``[$tag``]*" }
    Assert ([bool]$hit) "$tag reported for $file"
}
Assert (-not ($bad.Out -match '/crashed\]')) 'no check crashed'

Write-Output '== baselines'
$baseline = Join-Path $root 'baselines/complexity.txt'
$one = @('-MatlabChecks', 'complexity', '-ExternalChecks', '', '-Target', 'sample_bad/complexity', '-Quiet')
$issue = (Invoke-Verify $one).Out | Where-Object { $_ -match '\[complexity/CABE\]' } | Select-Object -First 1
$key = $issue -replace '^(.+?):\d+:\d+: ', '$1: '
try {
    Set-Content $baseline $key
    Assert ((Invoke-Verify $one).Exit -eq 0) 'baselined issue is accepted'
    Set-Content $baseline @($key, 'sample_bad/gone.m: error: [complexity/CABE] fixed long ago')
    $stale = Invoke-Verify $one
    Assert ($stale.Exit -eq 1 -and ($stale.Out -match '\[complexity/baseline\]')) 'stale baseline entry fails'
    $null = Invoke-Verify ($one + '-Update')
    Assert (@(Get-Content $baseline).Count -eq 1) 'update-baselines removes stale entry only'
    Set-Content $baseline ''
    $upd = Invoke-Verify ($one + '-Update')
    Assert (($upd.Out -match 'refusing to add') -and -not (Get-Content $baseline -Raw).Trim()) 'update-baselines refuses additions'
}
finally { Remove-Item $baseline -ErrorAction SilentlyContinue }

Write-Output '== matlab/ and sample/ pass'
$clean = Invoke-Verify @('-Target', 'matlab sample', '-Quiet')
$clean.Out | Select-Object -Last 1
Assert ($clean.Exit -eq 0) 'matlab and sample pass'

Write-Output '== clean tree uses the branch diff, not the whole tree'
$branch = Invoke-Verify @('-Quiet')
$branchText = $branch.Out -join "`n"
$branch.Out | Select-Object -Last 1
Assert ($branch.Exit -eq 0) 'clean verify passes'
Assert ($branchText -match '(?m)^verify: file set: branch vs base \(') 'clean tree uses branch vs base'
Assert ($branchText -match '(?m)^verify: files: \(none\)$') 'clean branch matches its base'

Write-Output '== config walk from a subdirectory, explicit path only'
Push-Location (Join-Path $root 'sample/src')
try {
    $fromSub = Invoke-Verify @('-Target', 'resampleUniform.m', '-Quiet')
}
finally { Pop-Location }
$subText = $fromSub.Out -join "`n"
Assert ($fromSub.Exit -eq 0) 'subdirectory verify passes'
Assert ($subText -match '(?m)^verify: file set: explicit paths$') 'subdirectory run is explicit paths'
Assert ($subText -match '(?m)^verify: files: sample/src/resampleUniform\.m$') 'subdirectory path is only that file'
Assert ($subText -match 'SignalFunctionsTest/') 'subdirectory run executes the dependent test'
Assert ($subText -notmatch 'SensorLogTest') 'subdirectory run skips the independent test'

Write-Output '== dirty file: that file and its dependent tests only'
$sampleFile = Join-Path $root 'sample/src/resampleUniform.m'
$original = [IO.File]::ReadAllBytes($sampleFile)
try {
    $suffix = [Text.Encoding]::UTF8.GetBytes("`r`n% scope probe`r`n")
    [IO.File]::WriteAllBytes($sampleFile, $original + $suffix)
    $scoped = Invoke-Verify @('-Quiet')
}
finally { [IO.File]::WriteAllBytes($sampleFile, $original) }
$scopeText = $scoped.Out -join "`n"
Assert ($scoped.Exit -eq 0) 'scoped verify passes'
Assert ($scopeText -match '(?m)^verify: file set: working tree \(staged and unstaged\)$') 'dirty tree uses the working tree'
Assert ($scopeText -match '(?m)^verify: files: sample/src/resampleUniform\.m$') 'dirty run checks only that file'
Assert ($scopeText -match 'SignalFunctionsTest/') 'dependent test runs'
Assert ($scopeText -notmatch 'SensorLogTest') 'independent test does not run'

if ($failures.Count) { Write-Output "selftest: FAIL ($($failures.Count))"; exit 1 }
Write-Output 'selftest: PASS'
