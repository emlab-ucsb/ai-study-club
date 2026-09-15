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
# Note: sandbox-exec is deprecated by Apple but still functional on Darwin 25.

set -eu

SESSION_DIR=$(cd "$(dirname "$0")" && pwd)
MODELS="fable opus sonnet haiku"

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

# The prompt goes last: claude reads a trailing positional argument as the first
# message of the session.
cd "$TARGET"
exec sandbox-exec -f "$PROFILE" claude --safe-mode \
    --append-system-prompt-file "$SPEC" "$@" "$PROMPT"
