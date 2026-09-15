# Model selection

Session for 2026-09-16.

## Harness

A harness for running the *same* prompt past several Claude models side by side,
so the meeting can compare the four transcripts without anyone having peeked at
the others first.

`start.sh` opens a `claude --safe-mode` session in one model's subdirectory
(`fable/`, `opus/`, `sonnet/`, `haiku/`) on a prompt read from a file, wrapped
in a macOS `sandbox-exec` profile that:

- makes the three sibling directories unreadable (metadata still visible, so
  `ls` shows they exist),
- hides the repo's `.git` entirely — its object store would otherwise be a side
  channel into whatever the other sessions had committed,
- hides the state the CLI keeps outside the working directory (see below),
- blocks writes anywhere except that session's own directory.

```sh
./start.sh opus prompts/refactor.md
./start.sh haiku prompts/refactor.md
```

The prompt file is passed as the session's first message, so every model gets
byte-identical instructions. A task delivered through the system prompt would be
an odd setup and one more thing the comparison would have to control for. The
model itself comes from the directory name, so a session can't end up running in
the wrong folder.

## Unattended runs

Add `-p` and the session runs to completion on its own, writing its JSON result
— final message, cost, duration, turn count — to `runs/<model>.json`. All four
in parallel:

```sh
for m in fable opus sonnet haiku; do ./start.sh "$m" prompts/refactor.md -p & done; wait
```

Nobody is present to answer permission prompts in this mode, so it turns
approval off (`--permission-mode bypassPermissions`) and leans on the sandbox
instead. The alternative — letting prompts auto-deny — would halt each model at
a different arbitrary point and make the comparison one of permission luck. Note
what the sandbox does and doesn't cover: writes are confined, the network is
not. `BUDGET_USD` at the top of the script caps the spend per run; this build of
the CLI has no `--max-turns`, so that cap is the only other stopping point.

Results are written outside the sandbox so a run can't read its own transcript
back as source material. Anything after the prompt file is handed to `claude`
unchanged and overrides these defaults, e.g. `-p --output-format stream-json
--verbose` for the full transcript rather than a summary.

Note that the JSON result holds only the final message plus metrics — no tool
calls, so nothing the run fetched or posted shows up there. The full record is
the session transcript under `~/.claude/projects/`, keyed by the `session_id` in
the JSON. Also check `subtype` before trusting a file: a run that hits
`BUDGET_USD` ends with `error_max_budget_usd` and **no `result` key at all**, so
a capped run leaves you metrics and no answer.

## Sealing the side channels

Blocking the sibling directories is the easy half. The CLI keeps per-session
state outside the working directory, and every bit of it is a way around that:

- `~/.claude/projects/<working-dir-slugged>/*.jsonl` — the full transcript of a
  session: every edit, tool result and intermediate step, so rather more than
  the git objects would give up. The slug is the absolute path with
  non-alphanumerics replaced by dashes, i.e. computable, not secret.
- `~/.claude/history.jsonl` — prompts, keyed by project path.
- `~/.claude/file-history/` — snapshots of edited files.
- `~/.claude.json` — a per-project record.

`start.sh` denies reads on all of those for the *other* three models, plus the
slugs for this directory and the repo root, which hold the sessions that
designed the experiment and would tell a model it's one of four. Each session
keeps read access to its own. Denying these leaves the CLI working normally;
writes are still allowed, so transcripts are still recorded.

Run the check before a batch:

```sh
./start.sh check
```

It builds each model's profile, attempts every blocked read from inside that
sandbox, and exits non-zero if any returns data. This list will grow with CLI
versions, so it's worth asserting rather than trusting.

`spec.md` holds what's true for all four runs and *is* appended to each system
prompt — mainly the sandbox notes, so no one burns turns diagnosing the missing
git or the unreadable siblings. It's appended rather than put in a `CLAUDE.md`,
which `--safe-mode` ignores.

The four working directories are gitignored for the same reason `.git` is
blocked. Collect the results with `git add -f` once every run is finished.
