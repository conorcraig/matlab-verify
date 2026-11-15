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

Write-Output '== default target (matlab/ and sample/) passes'
$clean = Invoke-Verify @('-Quiet')
$clean.Out | Select-Object -Last 1
Assert ($clean.Exit -eq 0) 'default target passes'

if ($failures.Count) { Write-Output "selftest: FAIL ($($failures.Count))"; exit 1 }
Write-Output 'selftest: PASS'
