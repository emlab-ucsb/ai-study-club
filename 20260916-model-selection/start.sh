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
# Note: sandbox-exec is deprecated by Apple but still functional on Darwin 25.

set -eu

SESSION_DIR=$(cd "$(dirname "$0")" && pwd)
MODELS="fable opus sonnet haiku"

# Runaway cap for unattended runs. This build has no --max-turns, so the budget
# is the only stop short of the model deciding it is finished.
BUDGET_USD=5

usage() {
  echo "usage: $(basename "$0") <fable|opus|sonnet|haiku> <prompt-file> [claude args...]" >&2
  exit 1
}

MODEL=${1:-}
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

# The git object store is a side channel into the other sessions' work: even
# with their directories blocked, `git show` / `git log -p` would hand over
# anything that has been committed. Block the whole thing.
GIT_DIR=$(cd "$SESSION_DIR" && git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
DENY_GIT=""
[ -n "$GIT_DIR" ] && DENY_GIT="
    (subpath \"$GIT_DIR\")"

# The siblings this session must not be able to read.
DENY_READS=""
for m in $MODELS; do
  [ "$m" = "$MODEL" ] && continue
  DENY_READS="$DENY_READS
    (subpath \"$SESSION_DIR/$m\")"
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

cat > "$PROFILE" <<PROFILE_END
(version 1)
(allow default)

;; --- reads -------------------------------------------------------------
;; Sibling model directories are opaque: their contents cannot be read, and
;; they cannot even be listed. Metadata stays allowed, so \`ls\` in the parent
;; still shows that they exist.
(deny file-read-data$DENY_READS)
(allow file-read-metadata)

;; The git directory is hidden outright, metadata included. Its object store is
;; a side channel into the other sessions' committed work, and leaving it merely
;; unreadable still lets stat(2) find it — at which point the CLI injects a
;; branch/status/recent-commits section into the system prompt.
(deny file-read*$DENY_GIT)

;; --- writes ------------------------------------------------------------
;; Nothing is writable except this session's own directory and the state the
;; CLI needs to run. Combined with the read rule above, git is unusable from
;; inside the sandbox — collect results from outside it.
(deny file-write*)
(allow file-write*
    (subpath "$TARGET")
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
# message of the session.
cd "$TARGET"
if [ "$PRINT" -eq 1 ]; then
  exec sandbox-exec -f "$PROFILE" claude --safe-mode \
      --append-system-prompt-file "$SPEC" "$@" "$PROMPT" > "$OUT"
fi
exec sandbox-exec -f "$PROFILE" claude --safe-mode \
    --append-system-prompt-file "$SPEC" "$@" "$PROMPT"
