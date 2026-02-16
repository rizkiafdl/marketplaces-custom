---
description: Inject and persist Notion credentials for Claude Code plugin access
---

# Inject Credentials Plugin - Notion Configuration

## Overview

This skill documents the persistent configuration system for the **inject-credentials-plugin**, which automatically loads and injects Notion database credentials into every Claude Code session.

## What This Plugin Does

✅ Loads Notion database configuration from persistent storage
✅ Automatically injects credentials on session start
✅ Provides Notion context and export guidelines to Claude
✅ Makes database ID and URL available as environment variables
✅ Enables seamless markdown export to Notion

## Setup Instructions

### Quick Start

1. **Run the configuration setup script**:
   ```bash
   bash ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/scripts/notion-setup.sh
   ```

2. **Enter your Notion database details when prompted**:
   - Notion Data Source ID
   - Database Name
   - Database URL
   - Default Category for exports

3. **Restart Claude Code**:
   Configuration will be loaded automatically on the next session start.

## Configuration Storage

The plugin persists your configuration in:
```
~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/config/notion.conf
```

**Example configuration file:**
```
# Notion Configuration
# Generated on [timestamp]
NOTION_DATA_SOURCE_ID="sdadasdasd"
NOTION_DATABASE_NAME="Muhammad Rizki Main Notes"
NOTION_DATABASE_URL="https://www.notion.so/dasdadasdadad"
NOTION_DEFAULT_CATEGORY="Learning Engineering"
```

## Available Environment Variables

The following variables are automatically exported to your Claude Code session:

- `NOTION_DATA_SOURCE_ID`: Your Notion database data source ID
- `NOTION_DATABASE_NAME`: Human-readable database name
- `NOTION_DATABASE_URL`: Full URL to your Notion database
- `NOTION_DEFAULT_CATEGORY`: Default category for new pages

## How It Works

1. **Session Start Hook**: Triggers when you start Claude Code
2. **Config Loading**: The `session-start.sh` script reads from `config/notion.conf`
3. **Environment Setup**: Configuration is exported as environment variables
4. **Context Injection**: Claude receives the credentials as additional context
5. **Export Ready**: You can immediately request markdown exports

## How to Use

### Export Single Markdown File

In any Claude Code session, simply ask:
```
Export docs/my-file.md to Notion
```

### Export Multiple Files

```
Export all markdown files from the docs/ directory to Notion
```

### Check Available MD Files

Run the helper script:
```bash
~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/scripts/export-md.sh [directory]
```

## Updating Configuration

To update your Notion settings at any time:
```bash
bash ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/scripts/notion-setup.sh
```

The setup script will:
- Show your current configuration
- Prompt for changes
- Validate all inputs
- Save safely with proper permissions

## Security

🔒 **Security Features:**
- Config file permissions: `600` (owner read/write only)
- Credentials stored locally, never transmitted
- Configuration persists across sessions securely
- Setup script validates all input
- Proper quoting in config file for safe parsing

## Verification

To verify the plugin is working:

1. **Check that configuration is loaded**:
   ```bash
   echo $NOTION_DATA_SOURCE_ID
   ```
   Should display your configured Data Source ID.

2. **Test the hook script**:
   ```bash
   ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/hooks-handlers/session-start.sh
   ```
   Should output JSON with your Notion configuration.

3. **Start a new Claude Code session**:
   Ask: "What's my Notion data source ID?"
   Claude should know and display your configured ID.

## Troubleshooting

**Configuration not loading?**
- Run setup script: `bash scripts/notion-setup.sh`
- Verify config file exists: `cat config/notion.conf`
- Check file permissions: `ls -la config/notion.conf`

**Plugin not working?**
- Check script is executable: `ls -la hooks-handlers/session-start.sh`
- Verify hooks.json exists: `cat hooks/hooks.json`
- Restart Claude Code

**Exports failing?**
- Ensure official Notion plugin is installed
- Verify Notion authentication is active
- Check the data source ID is correct
- Run setup script again to verify configuration

## File Structure

```
inject-credentials-plugin/
├── .claude-plugin/
│   └── plugin.json                # Plugin metadata
├── hooks/
│   └── hooks.json                # SessionStart hook registration
├── hooks-handlers/
│   └── session-start.sh          # Loads config and injects credentials
├── config/
│   └── notion.conf               # Persistent configuration file
├── scripts/
│   ├── notion-setup.sh           # Configuration management script
│   └── export-md.sh              # MD file discovery helper
└── README.md                      # Full documentation
```

## Version

2.0.0 - Persistent configuration system

This creates a robust, persistent configuration system for your Notion integration with automatic credential injection on every Claude Code session!