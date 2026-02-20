#!/bin/bash
set -e

# Resolve config file with fallback chain:
# 1. Cache path (CLAUDE_PLUGIN_ROOT, where Claude Code runs hooks from)
# 2. Relative path (sibling to hooks-handlers directory)
# 3. Marketplace path (canonical config location)
CONFIG_FILE=""
CANDIDATE_PATHS=(
    "${CLAUDE_PLUGIN_ROOT:-__skip__}/config/notion.conf"
    "$(dirname "$0")/../config/notion.conf"
    "$HOME/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/config/notion.conf"
)

for candidate in "${CANDIDATE_PATHS[@]}"; do
    if [ "$candidate" != "__skip__/config/notion.conf" ] && [ -f "$candidate" ]; then
        CONFIG_FILE="$candidate"
        break
    fi
done

# Load configuration from file
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    # Source the config file to load variables
    source "$CONFIG_FILE"

    if [ ! -z "$NOTION_DATA_SOURCE_ID" ]; then
        # Export as environment variables for the session
        export NOTION_DATA_SOURCE_ID="$NOTION_DATA_SOURCE_ID"
        export NOTION_DATABASE_NAME="$NOTION_DATABASE_NAME"
        export NOTION_DATABASE_URL="$NOTION_DATABASE_URL"
        export NOTION_DEFAULT_CATEGORY="$NOTION_DEFAULT_CATEGORY"

        echo "✅ Notion configuration loaded successfully"
    else
        echo "Notion plugin: No Data Source ID configured. Run /inject-credentials-plugin:initiate-notion-db to set up."
        exit 1
    fi
else
    echo "Notion plugin: No config found. Run /inject-credentials-plugin:initiate-notion-db to set up."
    exit 1
fi

# Output the JSON context configuration
cat <<EOF
{
  "additionalContext": "# Notion Integration - Auto-Injected Credentials\n\n## Notion Database Configuration\n\n**Target Database**: $NOTION_DATABASE_NAME\n- **Data Source ID**: \`$NOTION_DATA_SOURCE_ID\`\n- **Database URL**: $NOTION_DATABASE_URL\n\n## Markdown Export Guidelines\n\nWhen the user requests to export markdown files to Notion:\n\n1. **Use the Notion MCP Tools**:\n   - Tool: \`mcp__plugin_Notion_notion__notion-create-pages\`\n   - Parent: \`{ \"data_source_id\": \"$NOTION_DATA_SOURCE_ID\" }\`\n\n2. **Required Page Properties**:\n   - \`title\`: Extract from filename or first heading\n   - \`Category\`: Default to \"$NOTION_DEFAULT_CATEGORY\" or ask user\n   - \`Doc name\`: Human-readable document name\n\n3. **Content Conversion**:\n   - Read the markdown file content\n   - Preserve formatting (headings, code blocks, lists)\n   - Convert to Notion-compatible markdown\n\n4. **Batch Export**:\n   - For multiple files, create pages in sequence\n   - Report success/failure for each file\n   - Provide Notion URLs for created pages\n\n## Quick Export Pattern\n\n\`\`\`javascript\n// For each markdown file:\n1. Read file content\n2. Extract title from filename or H1\n3. Call notion-create-pages with:\n   {\n     parent: { data_source_id: \"$NOTION_DATA_SOURCE_ID\" },\n     content: markdown_content,\n     properties: {\n       title: extracted_title,\n       Category: \"$NOTION_DEFAULT_CATEGORY\"\n     }\n   }\n\`\`\`\n\n## Available Notion Operations\n\n- Create pages: \`notion-create-pages\`\n- Update pages: \`notion-update-page\`\n- Search: \`notion-search\`\n- Fetch page: \`notion-fetch\`\n\n**Note**: This configuration is automatically loaded on every session start from the persistent config file."
}
EOF

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "SessionStart hook ran"
  }
}
EOF