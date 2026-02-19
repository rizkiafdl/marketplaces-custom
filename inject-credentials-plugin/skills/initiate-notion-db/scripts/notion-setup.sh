#!/bin/bash

MARKETPLACE_CONFIG="$HOME/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/config/notion.conf"
CACHE_BASE="${CLAUDE_PLUGIN_ROOT:+$(dirname "$CLAUDE_PLUGIN_ROOT")}"
CACHE_BASE="${CACHE_BASE:-__skip__}"

# Primary config is marketplace (canonical location)
CONFIG_FILE="$MARKETPLACE_CONFIG"
CONFIG_DIR="$(dirname "$CONFIG_FILE")"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

echo "=== Notion Database Configuration Setup ==="
echo ""

# Check if config already exists
if [ -f "$CONFIG_FILE" ]; then
    CURRENT_ID=$(grep "NOTION_DATA_SOURCE_ID=" "$CONFIG_FILE" | cut -d'=' -f2)
    if [ ! -z "$CURRENT_ID" ]; then
        echo "Current Notion Data Source ID: ${CURRENT_ID:0:8}...${CURRENT_ID: -4}"
        echo ""
        read -p "Do you want to update the configuration? (y/N): " UPDATE
        if [[ ! "$UPDATE" =~ ^[Yy]$ ]]; then
            echo "Configuration unchanged."
            exit 0
        fi
    fi
fi

echo ""
echo "--- Enter Notion Database Details ---"
echo ""

# Prompt for Data Source ID
read -p "Notion Data Source ID: " DATA_SOURCE_ID
DATA_SOURCE_ID="${DATA_SOURCE_ID// /}"

if [ -z "$DATA_SOURCE_ID" ]; then
    echo "❌ Error: Data Source ID cannot be empty"
    exit 1
fi

# Prompt for Database Name
read -p "Database Name (default: 'Main Notes'): " DB_NAME
DB_NAME="${DB_NAME:-Main Notes}"

# Prompt for Database URL
read -p "Database URL (e.g., https://www.notion.so/...): " DB_URL
DB_URL="${DB_URL// /}"

if [ -z "$DB_URL" ]; then
    echo "❌ Error: Database URL cannot be empty"
    exit 1
fi

if [[ "$DB_URL" != https://* ]]; then
    echo "❌ Error: Database URL must start with https://"
    exit 1
fi

# Prompt for Default Category
read -p "Default Category for exports (default: 'Learning Engineering'): " DEFAULT_CATEGORY
DEFAULT_CATEGORY="${DEFAULT_CATEGORY:-Learning Engineering}"

# Save to config file
cat > "$CONFIG_FILE" <<EOF
# Notion Configuration
# Generated on $(date)
NOTION_DATA_SOURCE_ID=$DATA_SOURCE_ID
NOTION_DATABASE_NAME=$DB_NAME
NOTION_DATABASE_URL=$DB_URL
NOTION_DEFAULT_CATEGORY=$DEFAULT_CATEGORY
EOF

# Set appropriate permissions
chmod 600 "$CONFIG_FILE"

# Sync config to all versioned cache directories
if [ -d "$CACHE_BASE" ]; then
    for VERSION_DIR in "$CACHE_BASE"/*/; do
        if [ -d "$VERSION_DIR" ]; then
            mkdir -p "${VERSION_DIR}config"
            if cp "$CONFIG_FILE" "${VERSION_DIR}config/notion.conf"; then
                chmod 600 "${VERSION_DIR}config/notion.conf"
            else
                echo "⚠️  Warning: Failed to sync config to ${VERSION_DIR}"
            fi
        fi
    done
fi

echo ""
echo "✅ Configuration saved successfully!"
echo "📍 Marketplace: $CONFIG_FILE"
echo "📍 Cache: synced to all versioned cache directories"
echo "🔑 Data Source ID: ${DATA_SOURCE_ID:0:8}...${DATA_SOURCE_ID: -4}"
echo "📚 Database: $DB_NAME"
echo "🏷️  Category: $DEFAULT_CATEGORY"
echo ""
echo "ℹ️  Restart Claude Code for changes to take effect"
