# Baseline handling for non-MATLAB checks; same semantics as verify.applyBaseline.
# Issue line:    file:line:col: severity: [check/id] message
# Baseline line: file: severity: [check/id] message   (sorted, no line/column)

$IssuePattern = '^(?<file>.+?):(?<line>\d+):(?<col>\d+): (?<sev>error|warning): \[(?<check>[^/\]]+)/(?<id>[^\]]+)\] (?<msg>.*)$'

function ConvertTo-BaselineKey([string]$Line) {
    if ($Line -match $IssuePattern) {
        return "$($Matches.file): $($Matches.sev): [$($Matches.check)/$($Matches.id)] $($Matches.msg)"
    }
    return $null
}

# Returns issue lines not accepted by baselines/<check>.txt, plus stale-entry lines.
# With -Update, removes stale entries from the file and never adds new ones.
function Invoke-Baseline([string]$Check, [string[]]$Issues, [string]$Root, [switch]$Update) {
    $file = Join-Path $Root "baselines/$Check.txt"
    $base = [System.Collections.Generic.List[string]]::new()
    if (Test-Path $file) {
        Get-Content $file | ForEach-Object { if ($_.Trim()) { $base.Add($_.Trim()) } }
    }
    $used = [bool[]]::new($base.Count)
    $remaining = foreach ($issue in $Issues) {
        $key = ConvertTo-BaselineKey $issue
        $hit = -1
        for ($i = 0; $i -lt $base.Count; $i++) { if (-not $used[$i] -and $base[$i] -ceq $key) { $hit = $i; break } }
        if ($hit -ge 0) { $used[$hit] = $true } else { $issue }
    }
    $stale = for ($i = 0; $i -lt $base.Count; $i++) { if (-not $used[$i]) { $base[$i] } }
    $kept = for ($i = 0; $i -lt $base.Count; $i++) { if ($used[$i]) { $base[$i] } }
    $rel = "baselines/$Check.txt"
    if ($Update) {
        if ($stale) {
            @($kept | Sort-Object) | Set-Content $file
            Write-Output "baseline ${rel}: removed $(@($stale).Count) fixed entries, $(@($kept).Count) remain"
        }
        if ($remaining) {
            Write-Output "baseline ${rel}: refusing to add $(@($remaining).Count) new issue(s); fix them instead"
        }
        $stale = @()
    }
    $remaining
    foreach ($s in $stale) {
        "${rel}:0:0: error: [$Check/baseline] Stale entry, the issue is fixed: `"$s`". Run 'just update-baselines' to remove it."
    }
}

Export-ModuleMember -Function ConvertTo-BaselineKey, Invoke-Baseline -Variable IssuePattern
