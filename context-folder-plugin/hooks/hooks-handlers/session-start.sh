#!/bin/bash
CONTEXT_DIR="$(pwd)/.context"
GLOBAL_CLAUDE_MD="$HOME/.claude/CLAUDE.md"
MARKER="<!-- context-folder-plugin:start -->"

# --- Part 1: Write rule to ~/.claude/CLAUDE.md (idempotent) ---
if ! grep -qF "$MARKER" "$GLOBAL_CLAUDE_MD" 2>/dev/null; then
  cat >> "$GLOBAL_CLAUDE_MD" <<'BLOCK'

<!-- context-folder-plugin:start -->
## Context Folder Convention

When creating any document (markdown, txt, notes, specs, diagrams, etc.):
- Save it to `.context/` at the project root (create the folder if needed)
- This allows future Claude Code sessions to auto-load it as context
<!-- context-folder-plugin:end -->
BLOCK
fi

# --- Part 2: Inject .context/ files as additionalContext ---
# Silent no-op if no .context folder exists
if [ ! -d "$CONTEXT_DIR" ]; then
  cat <<EOF
{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "Context folder plugin: no .context/ folder in $(pwd)"}}
EOF
  exit 0
fi

# Read all .md, .txt, .rst files sorted
CONTENT=""
FILE_LIST=""
while IFS= read -r -d '' file; do
  relative="${file#$CONTEXT_DIR/}"
  CONTENT+="### $relative\n\n$(cat "$file")\n\n---\n\n"
  FILE_LIST+="- $relative\n"
done < <(find "$CONTEXT_DIR" -type f \( -name "*.md" -o -name "*.txt" -o -name "*.rst" \) -print0 2>/dev/null | sort -z)

if [ -z "$CONTENT" ]; then
  cat <<EOF
{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "Context folder plugin: .context/ is empty"}}
EOF
  exit 0
fi

# Escape content for JSON using python3 (available on macOS)
ESCAPED=$(printf '%s' "$CONTENT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")

cat <<EOF
{
  "additionalContext": "# Project Context (.context/ folder)\n\nAuto-loaded from \`.context/\`:\n\n${FILE_LIST}\n\n---\n\n${ESCAPED}"
}
EOF

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Context folder plugin: loaded files from .context/"
  }
}
EOF
