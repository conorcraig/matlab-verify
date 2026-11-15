# MISS_HIT style check (mh_style, check mode). Prints contract issue lines.
# Usage: style.ps1 <paths...>        `just fix` applies the auto-fixable ones.
param([Parameter(ValueFromRemainingArguments)][string[]]$Paths)

$hints = @{
    'line_length'         = 'Wrap the line with ... continuation.'
    'naming_functions'    = 'Rename to lowerCamelCase.'
    'naming_parameters'   = 'Rename to lowerCamelCase.'
    'naming_classes'      = 'Rename to UpperCamelCase.'
    'file_length'         = 'Split the file.'
}

$raw = & python -m miss_hit_core.mh_style --brief @Paths 2>&1 | ForEach-Object { "$_" }
foreach ($line in $raw) {
    if ($line -match '^(?<file>[^:]+(?::[\\/][^:]*)?):(?<line>\d+):(?<col>\d+): (?<kind>style|warning|error): (?<msg>.*?)(?: \[(?<rule>[a-z_]+)\])?$') {
        $file = $Matches.file -replace '\\', '/'
        $msg = $Matches.msg.Trim()
        if ($Matches.kind -eq 'style') {
            $rule = $Matches.rule
            $hint = if ($hints.ContainsKey($rule)) { $hints[$rule] } else { "Run 'just fix' to apply it automatically." }
            $msg = $msg.Substring(0, 1).ToUpper() + $msg.Substring(1)
            "${file}:$($Matches.line):$($Matches.col): error: [style/$rule] $msg. $hint"
        }
        else {
            "${file}:$($Matches.line):$($Matches.col): warning: [style/mh_$($Matches.kind)] MISS_HIT: $msg. " +
            "Fix the code so MISS_HIT can parse it (see the parse check)."
        }
    }
    elseif ($line -match '^(?<file>[^:]+): error: (?<msg>.*)$') {
        "$($Matches.file):0:0: error: [style/mh_error] MISS_HIT: $($Matches.msg) Fix miss_hit.cfg or the file."
    }
}
