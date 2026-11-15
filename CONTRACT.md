# Verification contract

Minimum MATLAB is **R2024a**. Every MATLAB function, option and validator used by
the runner or by checked code must exist in R2024a. No paid add-ons.

## MATLAB checks

- Each check is standalone: `issues = verify.checks.<name>(files, cfg)` in
  `matlab/+verify/+checks/<name>.m`.
- `files`: string array of `.m` paths. `cfg`: decoded `config/verify.json`
  (`jsondecode(fileread(...))`).
- `issues`: struct array (possibly 0x1) with fields
  `file, line, column, severity, check, id, message`.
  - `file` string (path as given), `line`/`column` double (0 if unknown),
  - `severity` `"error"` or `"warning"` (anything else, e.g. `"info"`, is dropped),
  - `check` the check name, `id` a short stable id (e.g. `FCNLL`, `cycle`),
  - `message` must tell the reader how to fix it.
- Helper: `verify.issue(file, line, col, severity, check, id, message)` builds one.

## Runner

`verify.run(checkNames, files)` runs the listed checks in ONE MATLAB session,
applies baselines, prints one line per remaining issue:

    file:line:col: severity: [check/id] message

then a summary line, and exits 1 if any non-baselined issue remains.
A listed check whose function file is missing is skipped with a warning.

## Non-MATLAB checks

Justfile recipes (e.g. MISS_HIT `mh_style`) print the same line format.

## Baselines

`baselines/<check>.txt`: sorted unique lines `file: severity: [check/id] message`
(no line/column). Issue keys present in the baseline are accepted; any
remaining issue fails, and stale baseline entries also fail (exact diff).
`just update-baselines` only removes entries (ratchets down); it refuses additions.
Empty or missing baseline = nothing accepted.

## Adding a check

1. Write `matlab/+verify/+checks/<name>.m`.
2. Add `<name>` to `matlab_checks` in the `Justfile` (one line).

## Reserved (owned by the types worker; do not edit here)

- `matlab/+verify/+checks/types.m`, `matlab/+verify/+checks/naming.m`
- `matlab/+verify/+types/`, `matlab/+verify/+mtree/`

`types` and `naming` are already registered in the check list.
