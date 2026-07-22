# claude-md-demo

A deliberately tiny R project whose **only purpose is to demo how `CLAUDE.md` works**.

The code is silly on purpose (it rates penguins). Nobody should learn R from this.
What we're actually showing colleagues is:

1. What a repo looks like *before* it has any instructions for Claude.
2. Running `/init` so Claude scans the repo and drafts a `CLAUDE.md`.
3. Editing that draft into rules we actually want followed.
4. Watching Claude obey those rules in a later session.

## The setup being demoed

| File | Where | Who it applies to |
|---|---|---|
| `CLAUDE.md` | repo root, committed | everyone on the project |
| `CLAUDE.local.md` | repo root, gitignored | just you |
| `~/.claude/CLAUDE.md` | your home folder | all your projects |

Claude loads these automatically at the start of a session. They are standing
instructions — build commands, style rules, "never touch this file" — not
something you re-paste every conversation.

## The dummy project itself

An R package-ish layout:

```
R/            source
tests/        tests
DESCRIPTION   package metadata
```

Run the tests:

```r
testthat::test_dir("tests")
```

## Demo script (for the session)

- Show this repo has no `CLAUDE.md` yet.
- Run `/init`, read the draft out loud, point out what it inferred from
  `DESCRIPTION` and the test layout.
- Add one opinionated rule by hand (e.g. "always use `<-`, never `=`").
- Ask Claude to add a function and watch it follow the rule.

## TODO

- Logging examples — we'll add these in a later session.
