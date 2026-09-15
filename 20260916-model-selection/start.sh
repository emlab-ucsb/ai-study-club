#!/bin/sh
# Start a `claude --safe-mode` session inside one model subdirectory, wrapped in a
# macOS sandbox that makes the three sibling directories opaque and keeps all
# writes inside the directory the session started in.
#
#   ./start.sh opus prompts/refactor.md [extra claude args...]
#
# The prompt file is opened as the session's first message, so every model is
# handed byte-identical instructions.
#
# Pass -p/--print and the session runs unattended instead, writing its JSON
# result to runs/<model>.json. All four at once:
#
#   for m in fable opus sonnet haiku; do ./start.sh "$m" prompts/refactor.md -p & done; wait
#
# `./start.sh check` runs every read the sandbox is supposed to block and reports
# any that succeed. Worth running before a batch: the list of places the CLI
# keeps session state outside the working directory grows with CLI versions.
#
# Note: sandbox-exec is deprecated by Apple but still functional on Darwin 25.

set -eu

SESSION_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(dirname "$SESSION_DIR")
MODELS="fable opus sonnet haiku"

# Runaway cap for unattended runs. This build has no --max-turns, so the budget
# is the only stop short of the model deciding it is finished.
BUDGET_USD=5

# Where the CLI keeps transcripts, prompt history and file snapshots.
CLAUDE_STATE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

usage() {
  echo "usage: $(basename "$0") <fable|opus|sonnet|haiku> <prompt-file> [claude args...]" >&2
  echo "       $(basename "$0") check" >&2
  exit 1
}

# The git object store is a side channel into the other sessions' work: even
# with their directories blocked, `git show` / `git log -p` would hand over
# anything that has been committed. Block the whole thing.
GIT_DIR=$(cd "$SESSION_DIR" && git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)

# The name the CLI gives a working directory under its projects/ folder: the
# absolute path with every non-alphanumeric character replaced by a dash.
slug() {
  printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'
}

# Directories a session must not read the contents of, but may still see listed.
# The loop variable is _m rather than m: sh has no locals, and these run
# un-piped in check(), where clobbering the caller's loop variable would quietly
# hand every model the wrong deny list.
sibling_dirs() {
  for _m in $MODELS; do
    [ "$_m" = "$1" ] || echo "$SESSION_DIR/$_m"
  done
}

# Paths a session must not see at all. The sibling directories being sealed off
# is not enough on its own: the CLI writes a full transcript of every session --
# every edit, tool result and intermediate step, so rather more than the git
# objects give up -- to a projects/ subdirectory named after the working
# directory, and that name is computable rather than secret.
hidden_paths() {
  for _m in $MODELS; do
    [ "$_m" = "$1" ] || echo "$CLAUDE_STATE/projects/$(slug "$SESSION_DIR/$_m")"
  done

  # The sessions that built the harness, which discuss the experiment itself
  # and would tell a model it is being compared against three others.
  echo "$CLAUDE_STATE/projects/$(slug "$SESSION_DIR")"
  echo "$CLAUDE_STATE/projects/$(slug "$REPO_DIR")"

  # Prompt history is keyed by project path, file-history holds snapshots of
  # edited files, and .claude.json carries a per-project record. Denying reads
  # on all three leaves the CLI working; writes are still permitted.
  echo "$CLAUDE_STATE/history.jsonl"
  echo "$CLAUDE_STATE/file-history"
  echo "$HOME/.claude.json"
  echo "$HOME/.claude.json.backup"

  [ -n "$GIT_DIR" ] && echo "$GIT_DIR"
}

# write_profile <model> <path>
write_profile() {
  _model=$1
  _out=$2
  _target="$SESSION_DIR/$_model"

  _deny_data=""
  sibling_dirs "$_model" | while IFS= read -r _p; do
    printf '\n    (subpath "%s")' "$_p"
  done > "$_out.data"
  _deny_data=$(cat "$_out.data"); rm -f "$_out.data"

  # subpath throughout, including for the plain files: it covers a regular file
  # as well as literal does, and unlike literal it still covers a directory that
  # does not exist when the profile is written. A model that has not run yet has
  # no transcript directory, and that is exactly when a literal rule would leave
  # the one it later creates readable by everyone else.
  hidden_paths "$_model" | while IFS= read -r _p; do
    printf '\n    (subpath "%s")' "$_p"
  done > "$_out.all"
  _deny_all=$(cat "$_out.all"); rm -f "$_out.all"

  cat > "$_out" <<PROFILE_END
(version 1)
(allow default)

;; --- reads -------------------------------------------------------------
;; Sibling model directories are opaque: their contents cannot be read, and
;; they cannot even be listed. Metadata stays allowed, so \`ls\` in the parent
;; still shows that they exist.
(deny file-read-data$_deny_data)
(allow file-read-metadata)

;; Hidden outright, metadata included. These are the routes around the rule
;; above -- the git object store, and the state the CLI keeps under its own
;; config directory. Leaving the git directory merely unreadable still lets
;; stat(2) find it, at which point the CLI injects a branch/status/recent-commits
;; section into the system prompt.
(deny file-read*$_deny_all)

;; --- writes ------------------------------------------------------------
;; Nothing is writable except this session's own directory and the state the
;; CLI needs to run. Combined with the read rules above, git is unusable from
;; inside the sandbox — collect results from outside it.
(deny file-write*)
(allow file-write*
    (subpath "$_target")
    (subpath "$HOME/.claude")
    (subpath "$HOME/.local/state/claude")
    (subpath "$HOME/.local/share/claude")
    (subpath "$HOME/Library/Caches/claude-cli-nodejs")
    (literal "$HOME/.claude.json")
    (literal "$HOME/.claude.json.backup")
    (subpath "/private/tmp")
    (subpath "/private/var/folders")
    (subpath "/dev"))
PROFILE_END
}

# Attempt every blocked read from inside each model's own sandbox and report
# anything that comes back with data. A path that does not exist yet is called
# out separately: nothing to read is not the same as being unable to read.
check() {
  _probe=$(mktemp -t claude-probe)
  _profile=$(mktemp -t claude-sandbox)
  _paths=$(mktemp -t claude-paths)
  trap 'rm -f "$_probe" "$_profile" "$_paths"' EXIT INT TERM

  cat > "$_probe" <<'PROBE_END'
while IFS= read -r p; do
  if [ -d "$p" ]; then
    out=$(ls -A "$p" 2>/dev/null | head -1)
  else
    out=$(head -c 1 "$p" 2>/dev/null)
  fi
  if [ -n "$out" ]; then
    echo "  LEAK     $p"
  else
    echo "  blocked  $p"
  fi
done
PROBE_END

  _failed=0
  for m in $MODELS; do
    echo "$m:"
    write_profile "$m" "$_profile"
    { sibling_dirs "$m"; hidden_paths "$m"; } > "$_paths"

    # Absent paths are reported from out here, where they are still visible.
    # They cannot be probed -- an unreadable path and one with nothing in it
    # look alike from inside -- but the deny rule covers them all the same, so a
    # model that has not run yet is not a gap.
    _present=""
    while IFS= read -r p; do
      if [ -e "$p" ]; then
        _present="$_present$p
"
      else
        echo "  absent   $p (rule covers it once created)"
      fi
    done < "$_paths"

    _result=$(printf '%s' "$_present" | sandbox-exec -f "$_profile" sh "$_probe")
    echo "$_result"
    case $_result in *LEAK*) _failed=1 ;; esac
  done

  if [ "$_failed" -eq 1 ]; then
    echo "" >&2
    echo "readable paths found -- do not run the batch until they are denied" >&2
    exit 1
  fi
  echo ""
  echo "all blocked"
}

MODEL=${1:-}
[ "$MODEL" = "check" ] && { check; exit 0; }
case " $MODELS " in
  *" $MODEL "*) shift ;;
  *) usage ;;
esac

PROMPT_FILE=${1:-}
[ -n "$PROMPT_FILE" ] || usage
shift
[ -f "$PROMPT_FILE" ] || { echo "missing prompt file: $PROMPT_FILE" >&2; exit 1; }
PROMPT=$(cat "$PROMPT_FILE")
[ -n "$PROMPT" ] || { echo "empty prompt file: $PROMPT_FILE" >&2; exit 1; }

TARGET="$SESSION_DIR/$MODEL"
[ -d "$TARGET" ] || { echo "missing directory: $TARGET" >&2; exit 1; }

PRINT=0
for arg in "$@"; do
  case $arg in -p|--print) PRINT=1 ;; esac
done

# Every session gets the same spec, so none of them waste turns rediscovering
# the sandbox. Appended rather than placed in a CLAUDE.md, which --safe-mode
# ignores. The per-run task stays out of here and goes in as the first user
# message instead -- a task delivered via the system prompt is an odd setup, and
# this comparison shouldn't have to control for it.
SPEC="$SESSION_DIR/spec.md"
[ -f "$SPEC" ] || { echo "missing spec file: $SPEC" >&2; exit 1; }

PROFILE=$(mktemp -t claude-sandbox)
trap 'rm -f "$PROFILE"' EXIT INT TERM
write_profile "$MODEL" "$PROFILE"

# Defaults are placed in front of "$@", so anything given on the command line
# comes later and wins.
#
# --model is set from the directory name in both modes: --print never offers the
# in-session picker, and in interactive mode it closes off a mis-click that would
# quietly run one model in another's directory.
set -- --model "$MODEL" "$@"

if [ "$PRINT" -eq 1 ]; then
  # There is nobody present to answer a permission prompt. Letting prompts
  # auto-deny instead would stop each model at a different arbitrary point and
  # turn the comparison into one of permission luck, so approval is switched off
  # and the sandbox above is what actually holds the line. It holds writes; the
  # profile leaves the network open.
  set -- --permission-mode bypassPermissions \
         --output-format json \
         --max-budget-usd "$BUDGET_USD" "$@"

  # Results land outside the sandbox, one file per model: the session keeps its
  # own directory for its actual work, and no run can read its own transcript
  # back as though it were source material. This shell opens the redirect before
  # sandbox-exec takes over, so the write is allowed.
  mkdir -p "$SESSION_DIR/runs"
  OUT="$SESSION_DIR/runs/$MODEL.json"
  echo "$MODEL -> $OUT" >&2
fi

# The prompt goes last: claude reads a trailing positional argument as the first
# message of the session. </dev/null keeps print mode from spending three
# seconds waiting on a stdin that is never coming.
cd "$TARGET"
if [ "$PRINT" -eq 1 ]; then
  exec sandbox-exec -f "$PROFILE" claude --safe-mode \
      --append-system-prompt-file "$SPEC" "$@" "$PROMPT" </dev/null > "$OUT"
fi
exec sandbox-exec -f "$PROFILE" claude --safe-mode \
    --append-system-prompt-file "$SPEC" "$@" "$PROMPT"
