set shell := ["pwsh", "-NoLogo", "-NoProfile", "-Command"]

# MATLAB checks: matlab/+verify/+checks/<name>.m, run in one session by verify.run.
# Adding a check is one line: append its name here.
matlab_checks := "parse lint compat complexity deps tests types naming"

# Non-MATLAB checks: tools/checks/<name>.ps1, printing the same issue line format.
external_checks := "style"

verifier := "'" + justfile_directory() + "/tools/verify.ps1' -MatlabChecks '" + matlab_checks + "' -ExternalChecks '" + external_checks + "'"

# No target: git working tree, or this branch vs its base when the tree is clean.
# Explicit paths: only those paths. Never the whole tree. See CONTRACT.md.
[no-cd]
verify *target:
    @{{verifier}} -Target '{{target}}'

# Agent entry point: only issues (bounded by tools/summarize.ps1), then one summary line.
[no-cd]
verify-quiet *target:
    @{{verifier}} -Target '{{target}}' -Quiet

# Remove fixed entries from baselines/*.txt. Never adds entries.
[no-cd]
update-baselines *target:
    @{{verifier}} -Target '{{target}}' -Update

# Apply MISS_HIT's automatic style fixes.
fix *target='matlab sample':
    @python -m miss_hit_core.mh_style --fix {{target}}

# Prove every check catches its sample_bad case and the clean target passes.
selftest:
    @./tools/selftest.ps1
