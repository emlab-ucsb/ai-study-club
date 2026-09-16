#!/bin/sh
# Run one prompt past several Claude models, each sealed off from the others.
#
#   ./start.sh opus    prompts/refactor.md [extra claude args...]
#   ./start.sh all     prompts/refactor.md [extra claude args...]
#   ./start.sh nofable prompts/refactor.md [extra claude args...]
#   ./start.sh check
#
# Sessions do not run in this repo. Each one works in a throwaway directory
# under $TMPDIR named after a letter -- a/, b/, c/, d/ -- and its output is
# copied back to results_<model>/<task>/ here once it exits. Nothing a session can see
# names the repo, the task or which model it is, so nothing points it at the
# published results of earlier runs; the repo itself is unreadable from inside
# the sandbox, `.git` included.
#
# The prompt file is passed as the session's first message and the spec as
# appended system prompt text, both read out here, so neither has to be readable
# from in there.
#
# Note: sandbox-exec is deprecated by Apple but still functional on Darwin 25.

set -eu

SESSION_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(dirname "$SESSION_DIR")
MODELS="fable opus sonnet haiku"
LETTERS="a b c d"

# Runaway cap for unattended runs. This build has no --max-turns, so the budget
# is the only stop short of the model deciding it is finished.
BUDGET_USD=5

# Where the CLI keeps transcripts, prompt history and file snapshots.
CLAUDE_STATE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

usage() {
  echo "usage: $(basename "$0") <fable|opus|sonnet|haiku> <prompt-file> [claude args...]" >&2
  echo "       $(basename "$0") all <prompt-file> [claude args...]" >&2
  echo "       $(basename "$0") nofable <prompt-file> [claude args...]" >&2
  echo "       $(basename "$0") check" >&2
  exit 1
}

# The name the CLI gives a working directory under its projects/ folder: the
# absolute path with every non-alphanumeric character replaced by a dash.
slug() {
  printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'
}

# task_of <prompt-file> -- the subdirectory results are collected into.
task_of() {
  _t=$(basename "$1")
  _t=${_t%.*}
  case $_t in
    ""|*/*) echo "bad prompt file name: $1" >&2; exit 1 ;;
  esac
  printf '%s' "$_t"
}

# letter_of <model> -- which working directory that model gets. Positional, so
# the four are interchangeable from inside: a session sees its siblings listed
# as bare letters and has nothing to match them against.
letter_of() {
  _want=$1
  _i=1
  for _m in $MODELS; do
    _n=1
    for _l in $LETTERS; do
      [ "$_n" = "$_i" ] && { [ "$_m" = "$_want" ] && { printf '%s' "$_l"; return 0; }; }
      _n=$((_n + 1))
    done
    _i=$((_i + 1))
  done
  echo "no letter for model: $_want" >&2
  exit 1
}

# A batch root holding one directory per model. Resolved with pwd -P because
# the sandbox matches real paths and $TMPDIR is reached through a symlink.
make_root() {
  _r=$(cd "$(mktemp -d)" && pwd -P)
  for _l in $LETTERS; do
    mkdir -p "$_r/$_l"
  done
  printf '%s' "$_r"
}

# write_profile <model> <root> <path>
write_profile() {
  _model=$1
  _root=$2
  _out=$3
  _run="$_root/$(letter_of "$_model")"

  _siblings=""
  for _l in $LETTERS; do
    [ "$_root/$_l" = "$_run" ] && continue
    _siblings="$_siblings
    (subpath \"$_root/$_l\")"
  done

  cat > "$_out" <<PROFILE_END
(version 1)
(allow default)

;; --- reads -------------------------------------------------------------
;; The other sessions' directories are opaque: their contents cannot be read,
;; and they cannot be listed. Metadata stays allowed, so \`ls\` one level up
;; still shows that they exist.
(deny file-read-data$_siblings)
(allow file-read-metadata)

;; The repository is hidden outright, metadata included. Sessions run outside
;; it and have no business reading it: it holds the other models' collected
;; results, the harness that explains the experiment, and a .git whose object
;; store would hand over anything committed. Hiding the lot also keeps the CLI
;; from finding a repository to summarise into the system prompt.
(deny file-read*
    (subpath "$REPO_DIR"))

;; Prompt history is keyed by project path, file-history holds snapshots of
;; edited files, and .claude.json carries a per-project record.
(deny file-read*
    (subpath "$CLAUDE_STATE/history.jsonl")
    (subpath "$CLAUDE_STATE/file-history")
    (subpath "$HOME/.claude.json")
    (subpath "$HOME/.claude.json.backup"))

;; The transcript store is denied wholesale and this session's own directory
;; allowed back. Naming the rivals individually would only hold while every
;; session ran where the script expected, since a transcript directory is named
;; after the working directory. Ordering is load-bearing -- last match wins, so
;; the allow must follow the deny or a session loses its own transcript.
(deny file-read*
    (subpath "$CLAUDE_STATE/projects"))
(allow file-read*
    (subpath "$CLAUDE_STATE/projects/$(slug "$_run")"))

;; --- writes ------------------------------------------------------------
;; Only this session's own directory, and the state the CLI needs to run.
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

;; Last, so it wins over the temp-directory allow above: the batch root is in
;; there, and a session must not be able to write into a sibling's directory
;; any more than it can read one.
(deny file-write*$_siblings)
PROFILE_END
}

# Attempt every blocked read from inside each model's own sandbox and report
# anything that answers with data.
check() {
  _probe=$(mktemp -t claude-probe)
  _profile=$(mktemp -t claude-sandbox)
  _root=$(make_root)
  trap 'rm -f "$_probe" "$_profile"; rm -rf "$_root"' EXIT INT TERM

  # Something to find, so a blocked read is distinguishable from an empty one.
  for _l in $LETTERS; do
    echo "sibling-content" > "$_root/$_l/planted.txt"
  done

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
    _run="$_root/$(letter_of "$m")"
    _own="$CLAUDE_STATE/projects/$(slug "$_run")"
    echo "$m ($(letter_of "$m")):"
    write_profile "$m" "$_root" "$_profile"

    _paths=""
    for _l in $LETTERS; do
      [ "$_root/$_l" = "$_run" ] && continue
      _paths="$_paths$_root/$_l
"
    done
    _paths="$_paths$REPO_DIR
$CLAUDE_STATE/history.jsonl
$CLAUDE_STATE/file-history
$HOME/.claude.json
$HOME/.claude.json.backup
"
    _result=$(printf '%s' "$_paths" | sandbox-exec -f "$_profile" sh "$_probe")
    echo "$_result"
    case $_result in *LEAK*) _failed=1 ;; esac

    # Every transcript directory on the machine, not just this batch's: the
    # rule denies the whole store, so anything readable here is a hole.
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

    # A session must still be able to write its own directory, or the run dies
    # for reasons that look like the model's fault.
    if sandbox-exec -f "$_profile" sh -c "echo ok > '$_run/.probe' && rm -f '$_run/.probe'" 2>/dev/null; then
      echo "  own      $_run (writable, as intended)"
    else
      echo "  BROKEN   $_run (own directory not writable)"
      _failed=1
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

# Run a set of models on one prompt, at the same time.
run_all() {
  _models=$1
  _prompt=$2
  shift 2
  [ -f "$_prompt" ] || { echo "missing prompt file: $_prompt" >&2; exit 1; }
  _task=$(task_of "$_prompt")

  # A batch is the worst time to discover the sandbox has stopped holding, so
  # it is asserted first. The subshell is deliberate: check() exits, not returns.
  if ! _chk=$(check 2>&1); then
    echo "$_chk" >&2
    exit 1
  fi
  echo "sandbox check passed -- launching $_task on: $_models"

  # One root for the batch, so each session has its siblings to be sealed off
  # from. Exported, so the children share it rather than each making their own;
  # this shell owns it and cleans it up.
  RUN_ROOT=$(make_root)
  export RUN_ROOT
  trap 'rm -rf "$RUN_ROOT"' EXIT INT TERM

  _pids=""
  for _model in $_models; do
    "$0" "$_model" "$_prompt" -p "$@" &
    _pids="$_pids $_model:$!"
  done

  # Bare `wait` reports success whichever way the children went, which would
  # hide a run that died on the budget cap or a subscription limit.
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
    _line=$(printf '  %-7s exit=%-3s %s' "$_who" "$_rc" \
        "$(summarize "$SESSION_DIR/tasks/$_task/$_who.json")")
    case $_line in *success*) ;; *) _fail=1 ;; esac
    _report="$_report$_line
"
  done

  echo ""
  echo "$_task:"
  printf '%s' "$_report"
  echo ""
  echo "results:  $SESSION_DIR/tasks/$_task/"
  echo "output:   $SESSION_DIR/results_<model>/$_task/"

  [ "$_fail" -eq 0 ] || { echo "not every run finished cleanly" >&2; exit 1; }
}

MODEL=${1:-}
if [ "$MODEL" = "all" ] || [ "$MODEL" = "nofable" ]; then
  # Letters still come from the full four-model list, so nofable leaves a/ empty
  # rather than shifting everyone up a directory: its three runs get the same
  # working directories, and the same sandbox shape, an `all` batch would give
  # them, and the two batches stay comparable.
  BATCH=""
  for _m in $MODELS; do
    [ "$MODEL" = "nofable" ] && [ "$_m" = "fable" ] && continue
    BATCH="${BATCH:+$BATCH }$_m"
  done
  shift
  [ -n "${1:-}" ] || usage
  run_all "$BATCH" "$@"
  exit 0
fi
if [ "$MODEL" = "check" ]; then
  check
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

# Every session gets the same spec, so none of them waste turns rediscovering
# the sandbox. It is read here and passed as text rather than by path: the repo
# is unreadable from inside, and --safe-mode ignores a CLAUDE.md anyway.
SPEC_FILE="$SESSION_DIR/spec.md"
[ -f "$SPEC_FILE" ] || { echo "missing spec file: $SPEC_FILE" >&2; exit 1; }
SPEC=$(cat "$SPEC_FILE")

# `all` exports a root for the whole batch. A lone run makes its own, with the
# other three directories present but empty, so the profile is the same shape
# either way.
OWN_ROOT=0
if [ -z "${RUN_ROOT:-}" ]; then
  RUN_ROOT=$(make_root)
  OWN_ROOT=1
fi
RUN_DIR="$RUN_ROOT/$(letter_of "$MODEL")"

PRINT=0
for arg in "$@"; do
  case $arg in -p|--print) PRINT=1 ;; esac
done

PROFILE=$(mktemp -t claude-sandbox)
cleanup() {
  rm -f "$PROFILE"
  [ "$OWN_ROOT" -eq 1 ] && rm -rf "$RUN_ROOT"
  return 0
}
trap cleanup EXIT INT TERM
write_profile "$MODEL" "$RUN_ROOT" "$PROFILE"

# Defaults are placed in front of "$@", so anything given on the command line
# comes later and wins. --model is set from the choice made out here: --print
# never offers the in-session picker, and the working directory no longer says
# which model this is.
set -- --model "$MODEL" "$@"

if [ "$PRINT" -eq 1 ]; then
  # There is nobody present to answer a permission prompt. Letting prompts
  # auto-deny instead would stop each model at a different arbitrary point and
  # turn the comparison into one of permission luck, so approval is switched off
  # and the sandbox is what holds the line. It holds files; the network is open.
  set -- --permission-mode bypassPermissions \
         --output-format json \
         --max-budget-usd "$BUDGET_USD" "$@"
  mkdir -p "$SESSION_DIR/tasks/$TASK"
  OUT="$SESSION_DIR/tasks/$TASK/$MODEL.json"
  echo "$MODEL -> $OUT" >&2
fi

# Not exec'd: the results have to be collected once the session is over.
# </dev/null keeps print mode from spending three seconds waiting on a stdin
# that is never coming.
cd "$RUN_DIR"
STATUS=0
if [ "$PRINT" -eq 1 ]; then
  sandbox-exec -f "$PROFILE" claude --safe-mode \
      --append-system-prompt "$SPEC" "$@" "$PROMPT" </dev/null > "$OUT" || STATUS=$?
else
  sandbox-exec -f "$PROFILE" claude --safe-mode \
      --append-system-prompt "$SPEC" "$@" "$PROMPT" || STATUS=$?
fi

# Collect whatever the session produced. Copied from out here, after the
# sandbox is gone -- the session could never write to the repo itself.
DEST="$SESSION_DIR/results_$MODEL/$TASK"
mkdir -p "$DEST"
if [ -n "$(ls -A "$RUN_DIR" 2>/dev/null)" ]; then
  cp -R "$RUN_DIR/." "$DEST/"
fi

exit "$STATUS"
