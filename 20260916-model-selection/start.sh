#!/bin/sh
# Start a `claude --safe-mode` session inside one model subdirectory, wrapped in a
# macOS sandbox that makes the three sibling directories opaque and keeps all
# writes inside the directory the session started in.
#
#   ./start.sh opus prompts/refactor.md [extra claude args...]
#
# The session runs in <model>/<prompt-file-basename>/ -- opus/refactor/ for the
# line above -- so a model writes its output there without being told to, and a
# second task does not land on top of the first. The prompt file is opened as
# the session's first message, so every model is handed byte-identical
# instructions; its name reaches the model only as the working directory.
#
# Pass -p/--print and the session runs unattended instead, writing its JSON
# result to tasks/<task>/<model>.json. All four at once:
#
#   ./start.sh all prompts/refactor.md [extra claude args...]
#
# which checks the sandbox first, refuses to launch if it is not holding, runs
# the four in parallel -- same hour, same API conditions, so whatever drifts
# drifts for everyone -- and reports how each one ended.
#
# `./start.sh check [prompt-file]` runs every read the sandbox is supposed to
# block and reports any that succeed. Worth running before a batch: the list of
# places the CLI keeps session state outside the working directory grows with
# CLI versions.
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
  echo "       $(basename "$0") all <prompt-file> [claude args...]" >&2
  echo "       $(basename "$0") check [prompt-file]" >&2
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

# task_of <prompt-file> -- the subdirectory a run of that prompt works in.
task_of() {
  _t=$(basename "$1")
  _t=${_t%.*}
  case $_t in
    ""|*/*) echo "bad prompt file name: $1" >&2; exit 1 ;;
  esac
  printf '%s' "$_t"
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

# Paths a session must not see at all, beyond the transcript store that
# write_profile denies wholesale.
hidden_paths() {
  # Prompt history is keyed by project path, file-history holds snapshots of
  # edited files, and .claude.json carries a per-project record. Denying reads
  # on all three leaves the CLI working; writes are still permitted.
  echo "$CLAUDE_STATE/history.jsonl"
  echo "$CLAUDE_STATE/file-history"
  echo "$HOME/.claude.json"
  echo "$HOME/.claude.json.backup"

  [ -n "$GIT_DIR" ] && echo "$GIT_DIR"
}

# write_profile <model> <run-dir> <path>
write_profile() {
  _model=$1
  _run=$2
  _out=$3

  _deny_data=""
  sibling_dirs "$_model" | while IFS= read -r _p; do
    printf '\n    (subpath "%s")' "$_p"
  done > "$_out.data"
  _deny_data=$(cat "$_out.data"); rm -f "$_out.data"

  # subpath throughout, including for the plain files: it covers a regular file
  # as well as literal does, and unlike literal it still covers a directory that
  # does not exist when the profile is written.
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

;; Hidden outright, metadata included. The git object store, and the state the
;; CLI keeps under its own config directory. Leaving the git directory merely
;; unreadable still lets stat(2) find it, at which point the CLI injects a
;; branch/status/recent-commits section into the system prompt.
(deny file-read*$_deny_all)

;; The transcript store is denied wholesale and this session's own directory
;; allowed back, rather than the three rivals being named one by one. A
;; transcript directory is named after the working directory, so naming them
;; individually only holds while every session runs where this script expects;
;; point a run one directory deeper and the enumerated names quietly stop
;; matching anything, with no error to notice. Ordering is load-bearing --
;; last match wins, so the allow must follow the deny or a session loses
;; access to its own transcript.
(deny file-read*
    (subpath "$CLAUDE_STATE/projects"))
(allow file-read*
    (subpath "$CLAUDE_STATE/projects/$(slug "$_run")"))

;; --- writes ------------------------------------------------------------
;; Nothing is writable except this run's own directory and the state the CLI
;; needs to run. Combined with the read rules above, git is unusable from
;; inside the sandbox — collect results from outside it.
(deny file-write*)
(allow file-write*
    (subpath "$_run")
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
  _task=${1:-check}
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
    _run="$SESSION_DIR/$m/$_task"
    _own="$CLAUDE_STATE/projects/$(slug "$_run")"
    write_profile "$m" "$_run" "$_profile"
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

    # Every transcript directory on the machine, not just this session's four:
    # the rule denies the whole store, so anything readable here is a hole.
    _others=$(find "$CLAUDE_STATE/projects" -type d -mindepth 1 -maxdepth 1 ! -path "$_own" 2>/dev/null || true)
    _sweep=$(printf '%s\n' "$_others" | sandbox-exec -f "$_profile" sh "$_probe")
    _n=$(printf '%s\n' "$_others" | grep -c . || true)
    _leaks=$(printf '%s\n' "$_sweep" | grep LEAK || true)
    if [ -n "$_leaks" ]; then
      echo "$_leaks"
      _failed=1
    else
      echo "  blocked  all $_n transcript directories under projects/"
    fi

    # The allow rule has to survive the deny above it, or the session cannot
    # read back its own transcript. Only testable once the run has one.
    if [ -d "$_own" ]; then
      _mine=$(printf '%s\n' "$_own" | sandbox-exec -f "$_profile" sh "$_probe")
      case $_mine in
        *LEAK*) echo "  own      $_own (readable, as intended)" ;;
        *)      echo "  BROKEN   $_own (own transcript unreadable)"; _failed=1 ;;
      esac
    else
      echo "  own      $_own (no transcript yet)"
    fi
  done

  if [ "$_failed" -eq 1 ]; then
    echo "" >&2
    echo "sandbox is not holding -- do not run the batch" >&2
    exit 1
  fi
  echo ""
  echo "all blocked"
}

# How a finished run ended, read back out of its result file. The JSON the CLI
# writes is a single compact line, so sed is enough and the harness stays
# dependency-free.
summarize() {
  if [ ! -f "$1" ]; then
    printf 'no result file'
    return
  fi
  _st=$(sed -n 's/.*"subtype":"\([^"]*\)".*/\1/p' "$1")
  _tn=$(sed -n 's/.*"num_turns":\([0-9]*\).*/\1/p' "$1")
  _cost=$(sed -n 's/.*"total_cost_usd":\([0-9.]*\).*/\1/p' "$1")
  printf '%-22s turns=%-4s $%s' "${_st:-unknown}" "${_tn:-?}" "${_cost:-?}"
}

# Run every model on one prompt, at the same time.
run_all() {
  _prompt=$1
  shift
  [ -f "$_prompt" ] || { echo "missing prompt file: $_prompt" >&2; exit 1; }
  _task=$(task_of "$_prompt")

  # A batch is the worst time to discover the sandbox has stopped holding, so
  # it is asserted first and the whole thing refuses to start if it has. The
  # subshell is deliberate: check() exits rather than returns.
  if ! _chk=$(check "$_task" 2>&1); then
    echo "$_chk" >&2
    exit 1
  fi
  echo "sandbox check passed -- launching $_task on: $MODELS"

  _pids=""
  for _model in $MODELS; do
    "$0" "$_model" "$_prompt" -p "$@" &
    _pids="$_pids $_model:$!"
  done

  # Bare `wait` reports success whichever way the children went, which would
  # hide a run that died on the budget cap or a subscription limit. Each child
  # is waited on by pid so its status survives.
  _fail=0
  _report=""
  for _entry in $_pids; do
    _who=${_entry%%:*}
    _pid=${_entry#*:}
    if wait "$_pid"; then
      _rc=0
    else
      _rc=$?
      _fail=1
    fi
    _out="$SESSION_DIR/tasks/$_task/$_who.json"
    _line=$(printf '  %-7s exit=%-3s %s' "$_who" "$_rc" "$(summarize "$_out")")
    case $_line in *success*) ;; *) _fail=1 ;; esac
    _report="$_report$_line
"
  done

  echo ""
  echo "$_task:"
  printf '%s' "$_report"
  echo ""
  echo "results: $SESSION_DIR/tasks/$_task/"

  # Anything other than four clean successes is worth stopping over: a capped or
  # limit-stopped run writes a plausible-looking file with no answer in it.
  [ "$_fail" -eq 0 ] || { echo "not every run finished cleanly" >&2; exit 1; }
}

MODEL=${1:-}
if [ "$MODEL" = "all" ]; then
  shift
  [ -n "${1:-}" ] || usage
  run_all "$@"
  exit 0
fi
if [ "$MODEL" = "check" ]; then
  if [ -n "${2:-}" ]; then
    check "$(task_of "$2")"
  else
    check
  fi
  exit 0
fi
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

TASK=$(task_of "$PROMPT_FILE")
TARGET="$SESSION_DIR/$MODEL"

# One directory per task, so a second prompt does not land on top of the first.
# The model directory is created here too rather than being required up front:
# the four are gitignored, so a fresh clone has none of them, and the model name
# is already checked against $MODELS above -- a guard here would only catch a
# directory someone had deleted, which is not an error worth stopping for.
RUN_DIR="$TARGET/$TASK"
mkdir -p "$RUN_DIR"

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
write_profile "$MODEL" "$RUN_DIR" "$PROFILE"

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

  # Results land outside the sandbox, one file per model per task: the session
  # keeps its own directory for its actual work, and no run can read its own
  # transcript back as though it were source material. This shell opens the
  # redirect before sandbox-exec takes over, so the write is allowed.
  mkdir -p "$SESSION_DIR/tasks/$TASK"
  OUT="$SESSION_DIR/tasks/$TASK/$MODEL.json"
  echo "$MODEL -> $OUT" >&2
fi

# The prompt goes last: claude reads a trailing positional argument as the first
# message of the session. </dev/null keeps print mode from spending three
# seconds waiting on a stdin that is never coming.
cd "$RUN_DIR"
if [ "$PRINT" -eq 1 ]; then
  exec sandbox-exec -f "$PROFILE" claude --safe-mode \
      --append-system-prompt-file "$SPEC" "$@" "$PROMPT" </dev/null > "$OUT"
fi
exec sandbox-exec -f "$PROFILE" claude --safe-mode \
    --append-system-prompt-file "$SPEC" "$@" "$PROMPT"
