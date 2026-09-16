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

Each run works in `<model>/<prompt-basename>/` — `opus/refactor/` for the lines
above. The session's working directory *is* the task folder, so a model writes
its output there without being told to, and a second task doesn't land on top of
the first. The prompt file's name reaches the model only that way; its contents
are the whole message.

## Unattended runs

Add `-p` and the session runs to completion on its own, writing its JSON result
— final message, cost, duration, turn count — to `tasks/<task>/<model>.json`. All
four in parallel:

```sh
./start.sh all prompts/refactor.md
```

`all` runs `check` first and refuses to launch if the sandbox isn't holding,
then starts the four together. Parallel is the better experimental choice as
well as the faster one: same hour, same API conditions, so whatever drifts
drifts for everyone equally. It waits on each run by pid rather than using a
bare `wait`, which reports success whichever way the children went, and prints
how each one ended:

```
probe:
  fable   exit=0   success   turns=2   $0.5316645
  opus    exit=0   success   turns=2   $0.2643825
  sonnet  exit=0   success   turns=2   $0.1402604
  haiku   exit=0   success   turns=2   $0.0152119
```

Anything other than four clean successes exits non-zero — a run stopped by the
budget cap or a subscription limit leaves a plausible-looking file with no
answer in it.

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

The transcript store is denied *wholesale* and the run's own directory allowed
back, rather than the three rivals being named one by one. Naming them
individually only holds while every session runs exactly where the script
expects: a transcript directory is named after the working directory, and
`subpath` matches containment rather than string prefix, so moving a run one
folder deeper leaves the enumerated names matching nothing — silently, with no
error to notice. Ordering is load-bearing, since the last matching rule wins:

```
(deny  file-read* (subpath ".../projects"))
(allow file-read* (subpath ".../projects/<this run's slug>"))
```

Reversed, the deny swallows the allow and a session loses access to its own
transcript. Prompt history, file snapshots and `.claude.json` are denied
outright, to every session including its own. All of it leaves the CLI working
normally; writes are untouched, so transcripts are still recorded.

Run the check before a batch:

```sh
./start.sh check [prompt-file]
```

It builds each model's profile and, from inside that sandbox, attempts every
blocked read plus a sweep of *every* transcript directory on the machine — not
just this session's four — exiting non-zero if any returns data. It also checks
the other direction, that the run can still read its own transcript, which only
works once that run has one. Pass the prompt file to check the paths a real run
of that task will use.

`spec.md` holds what's true for all four runs and *is* appended to each system
prompt — mainly the sandbox notes, so no one burns turns diagnosing the missing
git or the unreadable siblings. It's appended rather than put in a `CLAUDE.md`,
which `--safe-mode` ignores.

The four working directories are gitignored for the same reason `.git` is
blocked. Collect the results with `git add -f` once every run is finished.
