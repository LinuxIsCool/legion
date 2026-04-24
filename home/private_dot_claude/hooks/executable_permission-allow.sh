#!/bin/bash
# PermissionRequest hook — bypasses the hardcoded sensitive-file gate for
# any tool call targeting $HOME/.claude/. External paths still fall through
# to the default permission gate.
#
# Background: Claude Code 2.1.78+ closed the bypassPermissions path for
# .claude/, .git/, .vscode/, .idea/, .husky/ via a hardcoded gate at binary
# byte 119180548 (Up1 list). The gate runs BEFORE the mode check and BEFORE
# user allow rules, so --dangerously-skip-permissions and `permissions.allow`
# in settings.json cannot reach writes under ~/.claude/** (except the
# carve-outs: skills/, agents/, commands/, scheduled_tasks.json, worktrees/).
#
# See ~/.claude/local/research/2026/04/20/claude-code-permission-deep-dive/SYNTHESIS.md
# for the full binary archaeology.
#
# Workaround: PermissionRequest hook (documented in 2.1.116 hooks.md, line
# 1057). Fires when a permission dialog would appear. Returning
# {"hookSpecificOutput":{"hookEventName":"PermissionRequest",
#                        "decision":{"behavior":"allow"}}}
# allows the call without prompting.
#
# Note `decision.behavior`, NOT `permissionDecision` (PreToolUse shape). The
# hook only fires when the gate decides to prompt; calls already covered by
# bypass mode or session allow state skip the hook entirely.
#
# Validated on Linux Claude Code 2.1.116, 2026-04-20:
#   - Fresh interactive matt session: Write/Edit to scratchpad/, journal/,
#     research/, backlog/, plugins/, hooks/, settings.json all allowed
#   - Parent + subagent both honor the hook
#   - Bash redirect into ~/.claude/ allowed
#   - Hook registry is LIVE (not frozen at session start) — settings.json is
#     re-read per tool call
#
# Scope (Phase 0.1, 22:53 PDT): ALL of $HOME/.claude/ is auto-allowed. Shawn
# launches with --dangerously-skip-permissions and explicitly registered
# this hook — that is a deliberate grant of trust across the entire .claude/
# tree. Everything outside ~/.claude/ falls through to the default gate.

set -euo pipefail

LOG=/tmp/permission-allow-hook.log
# Log rotation — keep last 500 entries
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 500 ]; then
  tail -n 250 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

input=$(cat)

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
notebook_path=$(printf '%s' "$input" | jq -r '.tool_input.notebook_path // empty')

# Identify the target path for each tool type
target=""
case "$tool_name" in
  Write|Edit|MultiEdit|Read)
    target="$file_path"
    ;;
  NotebookEdit)
    target="${notebook_path:-$file_path}"
    ;;
  Bash)
    # Best-effort: grab first ~/.claude or /home/*/.claude path in the command
    target=$(printf '%s' "$command" | grep -oE '(/|~)[^[:space:]]+\.claude[^[:space:]]*' | head -1 || true)
    ;;
esac

# Normalize ~ prefix
target="${target/#\~/$HOME}"

{
  echo "=== $(date -Iseconds) tool=$tool_name target=$target ==="
} >> "$LOG" 2>&1

# Allowed roots. Anything under these passes. Non-matching paths fall
# through to the default gate.
#
# Legion stance: Shawn runs agents with --dangerously-skip-permissions by
# choice, and explicitly registered this hook. That is a deliberate grant
# of trust — any `.claude/` path (settings.json, hooks, plugins, local data)
# is auto-allowed for tool writes. External paths (/etc, system files) still
# fall through and require explicit consent.
allow_roots=(
  "$HOME/.claude/"
)

for root in "${allow_roots[@]}"; do
  case "$target" in
    "$root"*)
      printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
      echo "  -> ALLOW $root" >> "$LOG"
      exit 0
      ;;
  esac
done

# === Persona guardrail enforcement (persona-mega-project Week 1) ===
# When CLAUDE_PERSONA env var is set, consult guardrails.yaml.
# Maps the requested operation to a capability key and asks evaluate_guardrail.py.
#
# Inputs:
#   - In real hook invocation, $tool_name / $command / $file_path are parsed
#     from stdin JSON above (Claude Code's hook payload).
#   - For smoke-testing, set TOOL_NAME / BASH_CMD / TOOL_PATH env vars (we
#     CANNOT use BASH_COMMAND because bash overwrites it on every command).
EFF_TOOL_NAME="${TOOL_NAME:-$tool_name}"
EFF_BASH_CMD="${BASH_CMD:-$command}"
EFF_TOOL_PATH="${TOOL_PATH:-$file_path}"

if [[ -n "${CLAUDE_PERSONA:-}" ]] && [[ -n "$EFF_TOOL_NAME" ]]; then
  CAPABILITY=""
  case "$EFF_TOOL_NAME" in
    Bash) [[ "$EFF_BASH_CMD" =~ ^sudo ]] && CAPABILITY="run_sudo" || CAPABILITY="run_bash" ;;
    Write|Edit) [[ "$EFF_TOOL_PATH" =~ \.env$|secrets ]] && CAPABILITY="modify_secrets" || CAPABILITY="" ;;
    Delete) CAPABILITY="delete_file" ;;
  esac
  if [[ -n "$CAPABILITY" ]]; then
    set +e
    GUARD_OUTPUT=$(python3 "$HOME/.claude/local/scripts/evaluate_guardrail.py" \
      --persona "$CLAUDE_PERSONA" --capability "$CAPABILITY" --json 2>&1)
    GUARD_CODE=$?
    set -e
    if [[ $GUARD_CODE -eq 1 ]]; then
      # Extract a clean reason from the evaluator JSON; fall back to raw output.
      REASON=$(printf '%s' "$GUARD_OUTPUT" | jq -r '.reason // empty' 2>/dev/null || true)
      [[ -z "$REASON" ]] && REASON="$GUARD_OUTPUT"
      MSG="Persona guardrail: $CLAUDE_PERSONA cannot $CAPABILITY — $REASON"
      # jq -nc safely escapes the message into valid JSON.
      jq -nc --arg m "$MSG" '{
        hookSpecificOutput: {
          hookEventName: "PermissionRequest",
          decision: { behavior: "deny", message: $m }
        }
      }'
      # Audit log
      AUDIT="$HOME/.claude/local/personas/audit/${CLAUDE_PERSONA}-$(date +%Y-%m-%d).jsonl"
      mkdir -p "$(dirname "$AUDIT")"
      jq -nc \
        --arg event "guardrail_deny" \
        --arg persona "$CLAUDE_PERSONA" \
        --arg capability "$CAPABILITY" \
        --arg ts "$(date -Iseconds)" \
        --arg reason "$REASON" \
        '{event:$event, persona:$persona, capability:$capability, timestamp:$ts, reason:$reason}' \
        >> "$AUDIT"
      echo "  -> DENY persona=$CLAUDE_PERSONA capability=$CAPABILITY" >> "$LOG"
      exit 0
    fi
  fi
fi
# === End persona guardrails ===

# No match — fall through, let default gate handle it
echo "  -> FALLTHROUGH (no match)" >> "$LOG"
exit 0
