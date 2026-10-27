# <PROJECT>: unattended run plan (AUTOPILOT)

Read in full at the start of every session and after every context reset.

## 0. Scope and deadline
- Goal: <one sentence>.
- Runs unattended from <start> to <end>. No new submissions after <time>.
  Final report at <path> by <time>.
- Branch: `<agent-branch>` (the only branch the agent commits and pushes to).

## 1. Hard rules
1. Max <N> jobs of this run at once (fewer if others are queued on <partition>).
2. Memory: start at <X> GB; on OOM retry at <2X>, then <3X>, never more.
3. Files the agent may change: <list / folders>. Never: <list>.
4. Commits: small, on `<agent-branch>`, pushed after each step; message says
   what, why and the check result.
5. Deleting: never directly; only via dry-run scripts the human runs (or
   approves explicitly).
6. Anything outside these rules goes to `<FLAGS file>`, not into action.
7. Principles: <e.g. inputs from observed data only; masks are for display>.

## 2. Targets (acceptance criteria)
| Metric | Target |
|---|---|
| <metric> | <threshold> |
Then, as good as possible: <secondary metrics>.

## 3. Phases and gates
| Phase | What | Gate to move on |
|---|---|---|
| 0 | reproduce the baseline on this machine | <check> |
| 1 | <...> | <...> |
| n | confirmation with more replicates | sd within noise; all targets met |
Stop and report when: <conditions>.

## 4. Code-change protocol
1. Behind an option whose default reproduces the current behaviour.
2. Off check: rebuild a known version with the default; outputs byte-identical
   (except <known non-deterministic files>). Else fix before going on.
3. New major version number for runs with the option on.
4. Commit the change on its own with the off-check result.
5. Never edit a script a running job uses.

## 5. Tracking
- Journal `<path>` (newest first): every decision with numbers and job ids;
  STATUS block every <6> h.
- Plan table `<path>`: one row per version with its key metrics.
- Wake every 20-30 min while jobs run; hourly when idle.

## 6. Guardrails before accepting a result
- status DONE, no errors in logs, metrics file complete, all replicates
  complete (checked from outputs, not exit codes).
