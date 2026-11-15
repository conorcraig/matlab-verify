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
- Helper: `verify.issue(file, [line col], severity, check, id, message)` builds one
  (position is one argument so the helper stays within the 6-input lint limit).

## What `just verify` checks

No path argument: the `.m` files git shows as edited in the working tree
(staged and unstaged: added, copied, modified, renamed; deleted and untracked
files are not checked). If that set is empty, the `.m` files changed on this
branch versus its base (`git merge-base` with `origin/HEAD`, else
`origin/main`, `origin/master`, `main`, or `master`). The run prints which
set it used. It never defaults to the whole tree.

Explicit paths: only those paths. A folder means the `.m` files under it,
not the rest of the repository. Paths are resolved from the working directory.

Non-test checks (parse, lint, compat, complexity, style, types, naming, deps)
run only on that file set.

Tests are not assumed to live in one folder. The tests check runs any
selected file that is itself a test, plus tests that depend on the selected
files. It does not call `requiredFilesAndProducts` on the whole repository.
From the selected files it takes the function and class names they define,
`git grep`s those names, keeps files that are tests
(`matlab.unittest.TestCase`, `functiontests`, or a `methods (Test)` block),
then confirms with `matlab.codetools.requiredFilesAndProducts(..., 'toponly')`
on that candidate set only. A test stays when its required files intersect
the selected set. The tag filter stays `fast`.

`config/verify.json` is found by walking upward from the working directory.
The checker does not assume a fixed project folder name.

## Rules the runner holds itself to

`just verify matlab sample` must pass with no baselines, so runner code
follows its own `types` and `naming` rules:
input `arguments` blocks with class and size for every input, an
`arguments (Output)` block when there are outputs, lowerCamelCase functions
and variables. Exception: test methods of `matlab.unittest.TestCase`
subclasses cannot have `arguments` blocks (MATLAB throws
`MATLAB:unittest:TestCase:FunctionArgumentValidationNotSupported`).

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
