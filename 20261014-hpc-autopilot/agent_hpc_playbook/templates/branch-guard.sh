#!/usr/bin/env bash
# PreToolUse hook (Claude Code): allow git commit / push only on the agent's
# branch and never toward protected branches. Install as
# .claude/hooks/branch-guard.sh (chmod +x) and register it under
# hooks.PreToolUse with matcher "Bash" and "onFailure": "block"
# (see settings.local.json). Exit 2 blocks the call; stderr is the reason.
# Needs jq. Tested 2026-10-13 on sample commands (allows push/commit on the
# allowed branch; blocks pushes to protected branches incl. "git -C . push
# HEAD:refs/heads/main" and "/usr/bin/git push", and checkout/switch/reset).
# Re-test after edits, e.g.
#   echo '{"tool_input":{"command":"git push origin main"}}' | CLAUDE_PROJECT_DIR=$PWD ./branch-guard.sh; echo $?
ALLOWED_BRANCH="agent-branch"
PROTECTED='main|master|owf_wc_displace'

cmd=$(jq -r '.tool_input.command // empty')
[[ -z $cmd ]] && exit 0

# any git invocation that commits, pushes, or changes branch
if echo "$cmd" | grep -Eq '(^|[;&|[:space:]])([^[:space:]]*/)?git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+(push|commit|checkout|switch|merge|rebase|reset)\b'; then
  branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ $branch != "$ALLOWED_BRANCH" ]]; then
    echo "Blocked: git write operations allowed only on $ALLOWED_BRANCH (current: $branch)" >&2
    exit 2
  fi
  if echo "$cmd" | grep -Eq "(refs/heads/|:|[[:space:]])($PROTECTED)([[:space:]]|$)"; then
    echo "Blocked: command targets a protected branch ($PROTECTED)" >&2
    exit 2
  fi
  if echo "$cmd" | grep -Eq '\b(checkout|switch|merge|rebase|reset)\b'; then
    echo "Blocked: branch changes / history rewrites need the human" >&2
    exit 2
  fi
fi
exit 0
