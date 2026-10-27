# Playbook: supervised and unattended analysis runs with a coding agent on an HPC node

Lessons from running a long model calibration and production simulations with
Claude Code on the GRIT cluster (node `sequoia`, SLURM partition `emlab_nodes`),
October 2026. Written to be generic, as raw material for a reusable skill:
nothing here depends on the DISPLACE project except the examples. Templates are
in `templates/` (see the index at the end).

The pattern that worked: **a written plan with gates and rules, an agent that
submits SLURM jobs and wakes up to check them, a journal it keeps, small
commits on its own branch, and guardrails that make the risky things
impossible rather than discouraged.**

---

## 1. Before starting: the contract with the agent

Write it down in the repo (template: `templates/AUTOPILOT_TEMPLATE.md`):

- **Goal and acceptance criteria** as numbers (e.g. "trips, effort, catch
  within 5%; every R2 > 0.7"), plus what to optimise once they pass.
- **Phases with gates**: what must hold before moving on, and when to stop.
- **Hard rules**: job limits, memory, which files may change, commit policy,
  deadlines ("no new submissions after Monday 06:00"), what needs the human.
- **Code-change protocol**: every change behind an option whose default keeps
  the old behaviour; a byte-for-byte "off check" of the default before using it.
- **Where to put what is outside the rules**: a FLAGS file, not an action.
- **Principles stated once** (e.g. "inputs come from observed data only, never
  from earlier model runs"; "masks are for display, not calculations"). An
  agent optimises toward the target; without the principle it may pick a
  method you will reject.

Save durable preferences in the agent's memory as well, so a new session starts
with them.

## 2. Environment and reproducibility

- **Toolchain in user space, activated explicitly.** No sudo on the cluster: R
  (or Python) lives under `~/opt`, used through an `env.sh` that every job
  sources itself. Never rely on the login shell inside jobs.
- **`sbatch --wrap` runs `sh`**: use `. file`, not `source file`; prefer job
  scripts with `#!/usr/bin/env bash` (template: `templates/job.sbatch`).
- **Lockfiles are half the story.** List everything outside the lockfile
  (packages installed from git, report-only packages) in the setup docs. Put
  extras in a separate library so the project's environment stays clean.
- **Scan for dependencies before a long run** (e.g. every `pkg::` used by the
  code that will run). Finding missing packages one per 2-hour job is costly.
- **Prefer released binaries with checksums over building on the cluster.**
- **Cross-machine floating point.** Objects built on a laptop and recomputed on
  the cluster (another PROJ/GDAL/BLAS) differ in the last digits (1e-14):
  exact equality tests on geometries or doubles silently fail. Join on stable
  identifiers.
- **Write the full setup down** (from installing the language onward) before
  the instance can disappear. Mark reconstructed steps as such.

## 3. SLURM usage

- **Check the node first** (`sinfo -p <part> -o %C`, `squeue -p <part>`) and
  stay well under capacity; scale down when others have pending jobs.
- **Parallelise across independent replicates, one core each** (one job with N
  cores running N workers), rather than threads inside a run: it scales almost
  linearly; inner threading barely helps.
- **Measure memory and time on a small case** (`sacct -j <id>
  --format=JobID,Elapsed,MaxRSS`) and extrapolate; aggregation steps that load
  all replicates grow with their number.
- **Descriptive job names** (`prod_validation_1.0`, `calib_8.3L5`) so `squeue`
  tells the story.
- **Time limits** = measured time + margin, per step that scales.

## 4. Making long work restartable

- **Cache slow intermediate results** to disk before the fragile part
  (plotting, packaging). A late failure then costs minutes, not hours.
- **Separate build / run / post-process** into steps that can be re-run alone,
  each writing a status line.
- **Additive extensions**: e.g. add replicates 31-50 without rebuilding, with a
  guard that refuses to overwrite existing ones.
- **Completion from outputs, not exit codes**: check the last record written
  (some programs "fail" in teardown after finishing).
- **Never edit a script while a job runs it.** R and bash read scripts as they
  go; an edit mid-run broke the end of a job.

## 5. Supervision loop

- **Event-driven waits**: a background `until <done or failed>; do sleep 30;
  done` exits once and notifies; for recurring checks a self-scheduled wake-up
  every 20-60 min (template: `templates/watch_job.sh`).
- **Match every terminal state**, not only success: a watcher that greps for
  DONE stays silent through a crash.
- **Append-only logs**: status files keep lines from earlier attempts; read
  only the lines after the last "start" marker.
- **Keep watcher commands simple** (a stray backtick made a watcher "fail" while
  the job was fine).
- **Report the actual state** (queued / building / running / validating, with
  times) when asked, never a guess.
- **Journal** (template: `templates/JOURNAL_TEMPLATE.md`): newest first, every
  decision with its numbers and the job ids, a STATUS block every few hours.
  It survives context loss and is what the human reads.
- **Verify with data before explaining.** First explanations of surprising
  results were refined or corrected after a direct check (maps showing "no
  change" inside a closure turned out to be a display bug; a claim about a
  gradient needed a recomputation from raw positions).

## 6. Guardrails: folders, branches, destructive actions

Use layers; each covers gaps of the others. (Claude Code facts checked against
code.claude.com/docs on 2026-10-13: permissions, sandboxing, hooks, settings.)

### 6.1 Claude Code permission rules (`.claude/settings.local.json`)
Template: `templates/settings.local.json`.
- `Edit(...)` rules govern writes too (`Write(...)` path rules are accepted but
  never consulted); `Read(...)` governs reads.
- Paths: `//abs/path/**` absolute; `~/x` home; `/x` relative to the project
  (a single leading slash is not absolute); `./x` relative to the cwd.
- Evaluation: **deny, then ask, then allow; first match wins**. An allow never
  overrides a deny. Lists merge across user / project / local / managed
  settings; a deny anywhere wins; managed settings cannot be overridden.
- File access is limited to the launch directory plus
  `additionalDirectories`; `permissions.blockReadsOutsideWorkingDirectories`
  blocks reads elsewhere.
- **Bash rules are prefix matches on the command text** (`Bash(git push *)`):
  `git -C . push`, `/usr/bin/git push`, or a bare `git push` on the wrong branch
  are not caught. The docs call argument-level Bash rules fragile: treat them
  as guard rails.
- When the agent hits a deny it stops and asks; it must not route around it
  (e.g. writing the same content elsewhere without asking).

### 6.2 PreToolUse hook for branch rules
There is no built-in branch restriction in the local CLI. A PreToolUse hook
runs before every Bash call and blocks with exit code 2 (stderr = reason), even
calls an allow rule permits. It can check the real current branch, not only
the text. Template: `templates/branch-guard.sh` (registration in
`templates/settings.local.json`). Set `"onFailure": "block"` so a crashing hook
blocks. Test with sample JSON on stdin before relying on it.

### 6.3 Outside the agent (hard boundaries)
- **GitHub branch protection / rulesets** on main branches (PR required, no
  direct pushes): holds however git is invoked.
- **One clone or worktree per agent**, on its own branch.
- **Filesystem permissions**: raw data read-only for the account the agent uses.
- **Sandbox** (bubblewrap): Claude Code can confine Bash writes to listed
  folders and network to allowed domains; needs `bwrap` and `socat` installed
  by the admins (not available on sequoia in 2026-10).

### 6.4 Destructive actions
Only through reviewable scripts: dry run by default, `--delete` to act, a
protected list that makes the script refuse, a log of what was removed
(template: `templates/cleanup_template.sh`). Keep the outputs (results) folder
out of any delete list.

## 7. Data and outputs

- Data and results on shared project storage, not on the instance.
- Document what each output folder represents (e.g. "figures = seed 1,
  metrics = mean over seeds" caused confusion until written down).
- Keep the previous version next to a corrected one (`*_bug/`, `*_30rep/`).
- **Commit and push small and often** on the agent's branch; before an
  instance ends, move scratch scripts into the repo too.

## 8. Working style that helped

- Ask the human only when blocked on their decision; otherwise decide within
  the rules and log it.
- Before costly or irreversible runs, present the plan with time and resource
  estimates and wait for the go-ahead.
- Give results as a short table plus the one-paragraph meaning; flag
  limitations and corrections explicitly.

---

## Templates (`templates/`)

| File | Use |
|---|---|
| `AUTOPILOT_TEMPLATE.md` | the contract for an unattended run (phases, gates, rules) |
| `JOURNAL_TEMPLATE.md` | the running journal and STATUS block format |
| `job.sbatch` | SLURM job: environment, status lines, steps that can be resumed |
| `watch_job.sh` | wait for a job / status file to reach a terminal state |
| `settings.local.json` | Claude Code permissions for a project folder and branch |
| `branch-guard.sh` | PreToolUse hook: git commit/push only on the agent's branch |
| `cleanup_template.sh` | dry-run-by-default deletion with a protected list |
