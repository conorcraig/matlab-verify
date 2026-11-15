# Bounds verify output for agent consumption. Reads issue lines on stdin.
# Short input passes through unchanged. Long input is grouped by file and
# check/id with counts (first occurrence shown), capped at -MaxGroups.
param(
    [int]$MaxLines = 40,
    [int]$MaxGroups = 30,
    [Parameter(ValueFromPipeline)][string]$InputLine
)
begin { $lines = [System.Collections.Generic.List[string]]::new() }
process { if ($null -ne $InputLine) { $lines.Add($InputLine) } }
end {
    if ($lines.Count -le $MaxLines) { return $lines }

    $pattern = '^(?<file>.+?):(?<line>\d+):(?<col>\d+): (?<sev>\w+): \[(?<tag>[^\]]+)\] (?<msg>.*)$'
    $groups = [ordered]@{}
    $other = [System.Collections.Generic.List[string]]::new()
    foreach ($l in $lines) {
        if ($l -match $pattern) {
            $key = "$($Matches.file)|$($Matches.tag)"
            if (-not $groups.Contains($key)) { $groups[$key] = [pscustomobject]@{ First = $l; Count = 0; Lines = @() } }
            $groups[$key].Count++
            $groups[$key].Lines += $Matches.line
        }
        else { $other.Add($l) }
    }

    # Seam: a headless agent-harness call goes here later. It receives the
    # grouped text below and may return a shorter prioritised summary; on
    # failure or when unset, fall back to the deterministic grouping. No API
    # calls are made today.
    $summary = $null
    if ($summary) { return $summary }

    $shown = 0
    foreach ($g in $groups.Values) {
        if ($shown -ge $MaxGroups) { break }
        if ($g.Count -eq 1) { $g.First }
        else {
            $more = ($g.Lines | Select-Object -Skip 1 -First 8) -join ','
            "$($g.First)  (x$($g.Count); also lines $more$(if ($g.Count -gt 9) { ',...' }))"
        }
        $shown++
    }
    if ($groups.Count -gt $MaxGroups) {
        "... $($groups.Count - $MaxGroups) more file/check groups omitted; full list in the run's issues.txt"
    }
    $other | Select-Object -First 5
}
