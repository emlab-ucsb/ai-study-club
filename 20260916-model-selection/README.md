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
- blocks writes anywhere except that session's own directory.

```sh
./start.sh opus prompts/refactor.md     # then pick the model in-session
./start.sh haiku prompts/refactor.md
```

The prompt file is passed as the session's first message, so every model gets
byte-identical instructions. A task delivered through the system prompt would be
an odd setup and one more thing the comparison would have to control for.

`spec.md` holds what's true for all four runs and *is* appended to each system
prompt — mainly the sandbox notes, so no one burns turns diagnosing the missing
git or the unreadable siblings. It's appended rather than put in a `CLAUDE.md`,
which `--safe-mode` ignores.

The four working directories are gitignored for the same reason `.git` is
blocked. Collect the results with `git add -f` once every run is finished.
