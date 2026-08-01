# Claude.md and permissions demo

A deliberately tiny R project whose **only purpose is to demo how `CLAUDE.md`
works**.

The R code is incidental — a BigQuery query and a bar chart, just enough for
Claude to have something real to read. What we're demonstrating is how to give
Claude Code standing instructions about a repository, so you don't re-explain
the same things every session.

---

## 1. What `CLAUDE.md` is

A markdown file Claude Code reads automatically at the start of every session.
Whatever it says becomes standing instructions: build commands, style rules,
prohibitions, context that isn't obvious from the code.

It is not a config file the tool enforces. It is text placed into Claude's
context. That distinction matters and comes up again in step 5.

### The three locations

| File | Where | Applies to | Committed? |
|---|---|---|---|
| `CLAUDE.md` | repo root | that project, everyone on it | yes |
| `CLAUDE.local.md` | repo root | that project, just you | no — gitignore it |
| `~/.claude/CLAUDE.md` | your home folder | *every* project you work on | no — it's yours |

Project rules travel with the code. Personal rules travel with you. All
applicable files load together.

**Scope follows file location.** A `CLAUDE.md` in a subdirectory applies when
Claude works in that subdirectory.

---

## 2. The demo project

A small R project that gives Claude something real to read. `CLAUDE.md` is about
a codebase, so the demo needs a codebase — this is it.

```
R/program_impact.R      functions
sql/program_impact.sql  the query
figs/                   output
DESCRIPTION             metadata
```

It pulls program-level emissions totals for the 2024 BWBS season from
`emlab-gcp.ocean_ghg_bwbs.bwbs_program_impact` and plots two panels: actual vs.
counterfactual emissions by spatial domain, and the resulting impact.

```r
bigrquery::bq_auth()
source("R/program_impact.R")
save_program_impact()
```

That queries, plots, and writes `figs/program_impact.png`.

---

## 3. Generating the first draft with `/init`

`/init` scans the repo — structure, `DESCRIPTION`, test layout, existing docs —
and drafts a `CLAUDE.md`. It writes to Claude's **current working directory**,
so start the session where you want the file.

In this demo the session was running one level up, in `ai-study-club/`, so the
file landed at `ai-study-club/CLAUDE.md` rather than inside `20260722-claude-md-demo/`.
That was accepted deliberately, and the generated file notes that it should
move down if `ai-study-club/` ever holds a second project.

**The draft is a starting point, not the finished article.** It captures what's
inferable from the code. It cannot know your intent.

---

## 4. Editing it by hand

Just a markdown file. Edit freely.

### What works

- Exact commands, copy-pasteable
- Style rules that are otherwise ambiguous (`always use <-, never =`)
- Prohibitions tied to real hazards
- **Why** something is the way it is — context that's expensive to reconstruct
- Pointers to other docs (`read README.md before touching this directory`)

### What doesn't

- Vague aspirations (`write clean code`, `be careful`)
- Long files — 300 lines dilutes itself and the good rules get lost
- Anything already obvious from reading the code

Rules that we could add here:

```markdown
## Do not
- Do not add dependencies beyond bigrquery and ggplot2 — the point is a small
  file colleagues can read in one sitting.
- Do not reorganize this directory — the layout matches the walkthrough in the README.
```

Each maps to concrete damage: a demo nobody can follow,
files desynced from the presentation.

---

## 5. When edits take effect — and how far they go

`CLAUDE.md` loads at **session start**. Mid-session edits aren't picked up
automatically. To apply them:

- Ask Claude to "re-read `CLAUDE.md`" — no restart, smoothest for a live demo
- `/clear` (wipes the conversation history and starts a fresh session)
- Open a new chat
- Restart the editor (overkill)

### The honest limitation

`CLAUDE.md` is text in Claude's context, not a sandbox. A short file with
specific rules gets followed reliably. A rule buried on line 250 of a sprawling
one may not. The failure mode is confusing if you don't know this — *"but I
wrote it down."*

For anything with real money or real damage attached, `CLAUDE.md` alone isn't
enough. Step 8 covers the two mechanisms that actually enforce.

---

## 6. Creating `~/.claude/CLAUDE.md`

The personal global file. Not in any repo, not committed, colleagues don't get
it when they clone.

`~/.claude/` already exists — it's where Claude Code keeps its config — but the
`CLAUDE.md` inside it doesn't until you make it:

```bash
touch ~/.claude/CLAUDE.md && open -e ~/.claude/CLAUDE.md
```
You can execute the line above in the terminal to create and open the file or create it manually under `~/.claude/`. Include rules that apply to your general workflow, regardless of the repository. For example:

```markdown
## Data and cost safety

- Never run a BigQuery query without first running it with `--dry_run` and
  reporting the estimated bytes scanned. If the estimate exceeds 10 GB, stop
  and ask before running it.

## Repository hygiene

- Never commit generated files larger than 49 MB. Add them to `.gitignore`
  instead, and say so rather than committing silently.
```

The BigQuery rule illustrates the placement question well: there's no
BigQuery anywhere in this demo repo, so in a project file it would be
decoration. In the global file it applies to every project that *does* touch
BigQuery.

### Give every rule its reason

Compare:

> Never run a BigQuery query above 10Gb.

with:

> Never run a BigQuery query without first running it with `--dry_run` and
> reporting the estimated bytes scanned. If the estimate exceeds 10 GB, stop
> and ask before running it.

The second names the unit BigQuery actually bills on, and says what to do
instead of stopping. A prohibition with no alternative leaves Claude
improvising at exactly the wrong moment.

---

## 7. `CLAUDE.local.md` — the third slot

Same format as `CLAUDE.md`, plain markdown. Two differences: the filename, and
that you gitignore it (this repo's [`.gitignore`](../.gitignore) already does).
It loads alongside the others, so your rules layer on top of the shared ones.

It holds what's true for *you* on *this* project:

```markdown
- My R lives at /opt/homebrew/bin/R, not the system one. Use that for tests.
- Verbose explanations please, I'm still learning this codebase.
```

---

## 8. Enforcement: permissions and hooks

`CLAUDE.md` states intent. Two other mechanisms actually enforce, and both live
in `settings.json` rather than in `CLAUDE.md`:

1. `CLAUDE.md` — states the intent
2. **Permissions** — the harness refuses or prompts before the tool runs
3. **Hooks** — your own code inspects the call and decides

Only layers 2 and 3 are enforcement. Layer 1 is intent. For anything with real
money or real damage attached, use all three.

### Where settings live

| File | Scope | Commit it? |
|---|---|---|
| `~/.claude/settings.json` | all your projects | n/a |
| `.claude/settings.json` | this project, whole team | yes |
| `.claude/settings.local.json` | this project, just you | no — gitignore |

Same three-tier pattern as `CLAUDE.md`. They load user → project → local, with
later files overriding earlier ones.

**Scope decides where a rule goes.** Any rule works in any of the three files —
the question is how widely you want it to apply.

For example, an `allow` rule to `Bash(Rscript *)` in this repo's `.claude/settings.json` allows `Rscript` without asking. If placed in `~/.claude/settings.json` it allows it everywhere. Put it in the repo file when the rule is about
*this* project's tooling; put it in the global file when it's about how you
work. The same logic applies to `deny` rules: blocking `Read(./.env)` and
`Bash(rm -rf *)` is something you want in every project, so those belong in
`~/.claude/settings.json` rather than any single repo.

Because project settings load after user settings, a repo you clone can loosen
a rule you set globally.


### Permissions

Rules matching tool calls, sorted into three lists. The harness checks them
*before* the tool runs, so this is a real gate, not a suggestion.

```json
{
  "permissions": {
    "allow": ["Bash(Rscript *)", "Read"],
    "ask":   ["Bash(bq query *)"],
    "deny":  ["Bash(rm -rf *)", "Read(./.env)"]
  }
}
```

The three lists:

- `allow` — runs without prompting. For the safe, repetitive things you're
  tired of approving.
- `ask` — always prompts, even in modes that would otherwise auto-approve.
- `deny` — refused outright. Claude cannot override it.

Rule syntax is `Tool(pattern)`, and how broadly it matches depends on the
pattern:

| Rule | Matches |
|---|---|
| `Bash(Rscript R/program_impact.R)` | that exact command, nothing else |
| `Bash(git *)` | anything starting with `git` — `git status`, `git commit -m "x"` |
| `Read` | every use of the Read tool, any file |

The `*` is a trailing wildcard, so `git *` is a prefix match. Without it you get
a literal string comparison. `Bash(git status)` allows `git status`, which
prints the working tree state. It does **not** allow `git status --short`,
which prints the same thing in a compact one-line-per-file format — a different
string, so a different command as far as the rule is concerned.

Dropping the parentheses widens the rule to the whole tool. `Read` means all
reads; `Bash` on its own would mean every shell command — which is why bare
tool names belong in `allow` only when you've denied the dangerous cases
separately.

Each rule in the example, and why it's in the list it's in:

**`"Bash(Rscript *)"` in `allow`** — running the tests is safe and you'll do it
constantly. Without this, every `Rscript` call stops for approval and the demo
turns into clicking. `Rscript` reads and computes; it doesn't delete or deploy,
so there's little to gain from reviewing each invocation.

**`"Read"` in `allow`** — `Read` is the tool Claude uses to open a file and look
at its contents. A bare tool name with no pattern matches every use of it, so
this permits reading any file without asking.

Leave it out and nothing breaks — you just get a prompt for every file Claude
opens, and it opens a lot of them just to get oriented. In a live demo that
means your colleagues watch you approve file reads instead of watching the
demo.

It also depends on your permission mode: some modes auto-approve reads anyway,
so you may see no prompts even without this rule. The `allow` entry makes the
behaviour explicit rather than dependent on whichever mode happens to be
active.

This is only safe because `deny` below carves out the files that shouldn't be
read at all — allow-with-exceptions, not blanket trust.

**`"Bash(bq query *)"` in `ask`** — BigQuery bills by bytes scanned, so a
careless query costs real money. `ask` doesn't forbid it; it guarantees you see
the exact command before it runs. This is the enforcement version of the
`CLAUDE.md` rule from step 4 — that one states an intention, this one makes the
query impossible to run behind your back.

**`"Bash(rm -rf *)"` in `deny`** — recursive deletion is unrecoverable and
almost never what you actually want from an assistant. `deny` rather than `ask`
because there's no version of this you'd want to approve while distracted. If a
genuine need arises, you run it yourself.

**`"Read(./.env)"` in `deny`** — `.env` files hold API keys and credentials.
Denying the read keeps them out of the conversation entirely, which matters
because context can end up in transcripts and summaries. This is the exception
that makes the blanket `Read` allow reasonable: read anything, except the
secrets.

The general shape: `allow` what's frequent and harmless, `ask` what costs money
or is hard to undo, `deny` what you'd never approve anyway.

### Hooks

**A hook is a command that runs automatically when something happens in your
session.** You pick the moment, you pick the command.

Moments you can hook into:

| Event | Fires |
|---|---|
| `PreToolUse` | before Claude uses a tool — can block it |
| `PostToolUse` | after a tool succeeds |
| `SessionStart` | when a session begins |
| `Stop` | when Claude finishes responding |

Things you might wire to them: log every bash command to a file; run a
formatter after each edit; print the current git branch at session start.

**Why not just use permissions?** Permissions match patterns — *"does this
command start with `git`?"* A hook runs your own code, so it can decide
anything you can compute.

The BigQuery rule shows the gap. A permission rule can say "always ask before
`bq query`". It cannot say "allow it **only if** `--dry_run` is present" —
that needs someone to look inside the command. A hook can.

#### A worked example

The BigQuery rule from step 6, this time enforced rather than merely stated.
The nesting is three questions — **when**, **which tool**, **what to run**:

```json
{
  "hooks": {
    "PreToolUse": [{                                  // when
      "matcher": "Bash",                              // which tool
      "hooks": [{
        "type": "command",
        "if": "Bash(bq query *)",                     // narrowed to bq query
        "command": "jq -r '.tool_input.command' | grep -q -- '--dry_run' || { echo 'no --dry_run' >&2; exit 2; }"
      }]                                              // what to run
    }]
  }
}
```

The command extracts what Claude is about to run, greps it for `--dry_run`, and
exits 2 if the flag is missing. **Exit 2 is what blocks** — exit 0 lets the tool
through. `if` narrows the hook to `bq query`; without it, every `ls` and
`git status` would be blocked too.

Instead of `exit 2`, the command can `echo` a JSON response saying `"deny"`,
`"allow"` or `"ask"`, with a reason that reaches Claude. See the setup block
below for that version, or ask Claude to write you one.

Beyond `"type": "command"` there are `"prompt"` and `"agent"` hooks, which hand
the decision to a model instead of a script — useful when the check is
judgement-shaped rather than pattern-shaped.

#### Setting it up

To run the BigQuery example during the demo, create `.claude/settings.json` at
the repo root:

```json
{
  "permissions": {
    "ask": ["Bash(bq query *)"]
  },
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "if": "Bash(bq query *)",
        "command": "jq -r '.tool_input.command' | grep -q -- '--dry_run' || { echo 'Run with --dry_run first and report the estimated bytes scanned.' >&2; exit 2; }"
      }]
    }]
  }
}
```
Read the command as: *check for `--dry_run`; if it's missing, print a reason and
exit 2.* The `||` makes it conditional, so a query that already has the flag
passes through untouched.

From the terminal, that's:

```bash
mkdir -p .claude
touch .claude/settings.json
```
Paste the JSON contents in and save. You can also create it manually within the repo's `.claude` folder.

Then **open `/hooks` (from Claude chat) once** so the new file is picked up, or nothing fires.


### Which layer to reach for

| | Permissions | Hooks |
|---|---|---|
| Matches on | tool + command pattern | anything you can compute |
| Effort | one line of JSON | a script to write and test |
| Good for | "always ask before X" | "block X unless condition Y" |

Start with permissions. Reach for a hook only when the rule needs logic.




