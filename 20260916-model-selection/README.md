# Model selection

Session for 2026-09-16.

## Harness

A harness for running the *same* prompt past several Claude models side by side,
so the meeting can compare the four transcripts without anyone having peeked at
the others first.

`start.sh` opens a `claude --safe-mode` session in one model's subdirectory
(`fable/`, `opus/`, `sonnet/`, `haiku/`), wrapped in a macOS `sandbox-exec`
profile that:

- makes the three sibling directories unreadable (metadata still visible, so
  `ls` shows they exist),
- hides the repo's `.git` entirely — its object store would otherwise be a side
  channel into whatever the other sessions had committed,
- blocks writes anywhere except that session's own directory.

```sh
./start.sh opus            # then pick the model in-session and paste the prompt
./start.sh haiku
```

`sandbox-notes.md` is appended to each session's system prompt so no one burns
turns diagnosing the missing git or the unreadable siblings. It's appended
rather than put in a `CLAUDE.md`, which `--safe-mode` ignores.

The four working directories are gitignored for the same reason `.git` is
blocked. Collect the results with `git add -f` once every run is finished.
