function nFailing = run(checkNames, files, opts)
%RUN Run verification checks in one MATLAB session and report issues.
%   verify.run(checkNames, files) runs each verify.checks.<name>(files, cfg),
%   applies baselines/<check>.txt, prints one line per remaining issue and,
%   under -batch, exits 1 if any remain. Folders in FILES are expanded to the
%   .m files below them. A listed check with no function file is skipped
%   with a warning.
%
%   Options:
%     Mode       "check" (default) or "update" (ratchet baselines down only)
%     Verbose    print per-check progress and timing (default false)
%     Root       repository root holding config/ and baselines/
%     ReportDir  folder for per-run artifacts (default $VERIFY_REPORT_DIR)
arguments
    checkNames (1,:) string
    files (:,1) string
    opts.Mode (1,1) string {mustBeMember(opts.Mode, ["check", "update"])} = "check"
    opts.Verbose (1,1) logical = false
    opts.Root (1,1) string = verify.root()
    opts.ReportDir (1,1) string = string(getenv("VERIFY_REPORT_DIR"))
end
arguments (Output)
    nFailing (1,1) double
end
startTime = tic;
cfg = verify.loadConfig(opts.Root, opts.ReportDir);
files = verify.expandFiles(files);
verify.addSourcePaths(files);

nFailing = 0;
nBaselined = 0;
ran = strings(1, 0);
for name = checkNames
    if ~verify.checkExists(name)
        fprintf("warning: check '%s' not found (matlab/+verify/+checks/%s.m); skipped\n", name, name);
        continue
    end
    checkTime = tic;
    issues = verify.runCheck(name, files, cfg);
    if ~isempty(issues)
        issues = issues(ismember([issues.severity], ["error", "warning"]));
    end
    [remaining, stale, accepted] = verify.applyBaseline(name, issues, opts.Root, opts.Mode);
    verify.printIssues(name, remaining, stale, opts.Root);
    nFailing = nFailing + numel(remaining) + numel(stale);
    nBaselined = nBaselined + accepted;
    ran(end + 1) = name; %#ok<AGROW>
    if opts.Verbose
        fprintf("-- %-11s %3d issue(s), %d baselined, %5.1fs\n", name, numel(remaining), accepted, ...
            toc(checkTime));
    end
end

fprintf("verify(matlab): %d failing, %d baselined, %d files, checks [%s], %.1fs\n", ...
    nFailing, nBaselined, numel(files), strjoin(ran, " "), toc(startTime));
if batchStartupOptionUsed && nFailing > 0
    exit(1);
end
end
