#!/usr/bin/env bash
# plugin-manager.sh — allowedTools injection for Claude Code plugins
#
# Usage:
#   ./plugin-manager.sh inject <plugin-name>
#   ./plugin-manager.sh remove <plugin-name>
#   ./plugin-manager.sh list

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="${HOME}/.claude/settings.json"
TRACKING_FILE="${HOME}/.claude/plugins/plugin-allowed-tools.json"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() { echo "Error: $*" >&2; exit 1; }

ensure_settings_file() {
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    echo '{}' > "$SETTINGS_FILE"
  fi
}

ensure_tracking_file() {
  if [[ ! -f "$TRACKING_FILE" ]]; then
    mkdir -p "$(dirname "$TRACKING_FILE")"
    echo '{}' > "$TRACKING_FILE"
  fi
}

# Parse allowed-tools from a single SKILL.md file.
# Outputs one tool per line.
parse_allowed_tools() {
  local skill_file="$1"
  local in_frontmatter=0
  local frontmatter_count=0
  local in_allowed_tools=0

  while IFS= read -r line; do
    # Detect frontmatter delimiters
    if [[ "$line" == "---" ]]; then
      (( frontmatter_count++ )) || true
      if [[ $frontmatter_count -eq 1 ]]; then
        in_frontmatter=1
        continue
      elif [[ $frontmatter_count -eq 2 ]]; then
        # End of frontmatter
        break
      fi
    fi

    [[ $in_frontmatter -eq 0 ]] && continue

    # Detect "allowed-tools:" key
    if [[ "$line" =~ ^allowed-tools:[[:space:]]*$ ]]; then
      in_allowed_tools=1
      continue
    fi

    # If we hit another top-level key, stop collecting
    if [[ $in_allowed_tools -eq 1 && "$line" =~ ^[a-zA-Z] ]]; then
      in_allowed_tools=0
      continue
    fi

    # Collect list items under allowed-tools
    if [[ $in_allowed_tools -eq 1 && "$line" =~ ^[[:space:]]+-[[:space:]]+(.*) ]]; then
      echo "${BASH_REMATCH[1]}"
    fi
  done < "$skill_file"
}

# Collect all tools from all SKILL.md files under a plugin directory.
# Outputs a JSON array string, e.g. ["Read","Glob"]
collect_plugin_tools() {
  local plugin_dir="$1"
  local tools=()

  while IFS= read -r -d '' skill_file; do
    while IFS= read -r tool; do
      [[ -n "$tool" ]] && tools+=("$tool")
    done < <(parse_allowed_tools "$skill_file")
  done < <(find "$plugin_dir" -name "SKILL.md" -print0)

  # Deduplicate and build JSON array via Python3
  python3 - "${tools[@]+"${tools[@]}"}" <<'PYEOF'
import sys, json
seen = []
for t in sys.argv[1:]:
    if t not in seen:
        seen.append(t)
print(json.dumps(seen))
PYEOF
}

# ---------------------------------------------------------------------------
# inject <plugin-name>
# ---------------------------------------------------------------------------
cmd_inject() {
  local plugin_name="$1"
  local plugin_dir="${SCRIPT_DIR}/${plugin_name}"

  [[ -d "$plugin_dir" ]] || die "Plugin directory not found: $plugin_dir"

  ensure_settings_file
  ensure_tracking_file

  local tools_json
  tools_json="$(collect_plugin_tools "$plugin_dir")"

  local tool_count
  tool_count="$(python3 -c "import sys,json; print(len(json.loads(sys.argv[1])))" "$tools_json")"

  if [[ "$tool_count" -eq 0 ]]; then
    echo "No allowed-tools found in any SKILL.md under $plugin_dir"
    exit 0
  fi

  echo "Injecting $tool_count tool(s) for plugin '$plugin_name' into settings.json..."

  # Merge tools into settings.json and update tracking file
  python3 - "$SETTINGS_FILE" "$TRACKING_FILE" "$plugin_name" "$tools_json" <<'PYEOF'
import sys, json

settings_path = sys.argv[1]
tracking_path = sys.argv[2]
plugin_name   = sys.argv[3]
new_tools     = json.loads(sys.argv[4])

# --- Update settings.json ---
with open(settings_path) as f:
    settings = json.load(f)

existing = settings.get("allowedTools", [])
merged = list(existing)
for t in new_tools:
    if t not in merged:
        merged.append(t)
settings["allowedTools"] = merged

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

# --- Update tracking file ---
with open(tracking_path) as f:
    tracking = json.load(f)

tracking[plugin_name] = new_tools

with open(tracking_path, "w") as f:
    json.dump(tracking, f, indent=2)
    f.write("\n")

print(f"Done. allowedTools now has {len(merged)} entry(ies) in settings.json.")
PYEOF
}

# ---------------------------------------------------------------------------
# remove <plugin-name>
# ---------------------------------------------------------------------------
cmd_remove() {
  local plugin_name="$1"

  ensure_settings_file
  ensure_tracking_file

  python3 - "$SETTINGS_FILE" "$TRACKING_FILE" "$plugin_name" <<'PYEOF'
import sys, json

settings_path = sys.argv[1]
tracking_path = sys.argv[2]
plugin_name   = sys.argv[3]

# --- Load tracking file ---
with open(tracking_path) as f:
    tracking = json.load(f)

if plugin_name not in tracking:
    print(f"Plugin '{plugin_name}' not found in tracking file. Nothing to remove.")
    sys.exit(0)

tools_to_remove = set(tracking[plugin_name])
print(f"Removing {len(tools_to_remove)} tool(s) injected by '{plugin_name}'...")

# --- Update settings.json ---
with open(settings_path) as f:
    settings = json.load(f)

existing = settings.get("allowedTools", [])
remaining = [t for t in existing if t not in tools_to_remove]

if remaining:
    settings["allowedTools"] = remaining
else:
    settings.pop("allowedTools", None)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

# --- Remove plugin from tracking ---
del tracking[plugin_name]

with open(tracking_path, "w") as f:
    json.dump(tracking, f, indent=2)
    f.write("\n")

print(f"Done. '{plugin_name}' removed from settings and tracking file.")
PYEOF
}

# ---------------------------------------------------------------------------
# list
# ---------------------------------------------------------------------------
cmd_list() {
  ensure_tracking_file

  python3 - "$TRACKING_FILE" <<'PYEOF'
import sys, json

tracking_path = sys.argv[1]

with open(tracking_path) as f:
    tracking = json.load(f)

if not tracking:
    print("No plugins currently have injected tools.")
    sys.exit(0)

print(f"{'Plugin':<40}  Tools")
print("-" * 72)
for plugin, tools in sorted(tracking.items()):
    for i, tool in enumerate(tools):
        if i == 0:
            print(f"{plugin:<40}  {tool}")
        else:
            print(f"{'':40}  {tool}")
    print()
PYEOF
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args]

Commands:
  inject <plugin-name>   Inject allowed-tools from plugin SKILL.md files into settings.json
  remove <plugin-name>   Remove a plugin's injected tools from settings.json
  list                   List all plugins with their injected tools
EOF
}

[[ $# -ge 1 ]] || { usage; exit 1; }

COMMAND="$1"
shift

case "$COMMAND" in
  inject)
    [[ $# -eq 1 ]] || die "inject requires exactly one argument: <plugin-name>"
    cmd_inject "$1"
    ;;
  remove)
    [[ $# -eq 1 ]] || die "remove requires exactly one argument: <plugin-name>"
    cmd_remove "$1"
    ;;
  list)
    cmd_list
    ;;
  *)
    usage
    exit 1
    ;;
esac
