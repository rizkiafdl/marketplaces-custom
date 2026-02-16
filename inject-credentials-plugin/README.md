# Inject Credentials Plugin

A Claude Code plugin that automatically injects and persists Notion credentials and configuration into every session, enabling seamless markdown export to your Notion database.

## Overview

This plugin works alongside the official Notion plugin from Anthropic to provide:
- ✅ Persistent credential storage across sessions
- ✅ Automatic credential injection on session start
- ✅ Pre-configured data source for your Notion database
- ✅ Easy configuration management via setup script
- ✅ Helper scripts for batch markdown exports
- ✅ Consistent export workflow across all projects

## What It Does

When you start any Claude Code session, this plugin automatically:
1. Loads your Notion database configuration from persistent storage
2. Injects the configuration as environment variables
3. Provides export guidelines and patterns to Claude
4. Makes Claude aware of your target database

## Plugin Structure

```
inject-credentials-plugin/
├── .claude-plugin/
│   └── plugin.json                # Plugin metadata (v2.0.0)
├── hooks/
│   └── hooks.json                # SessionStart hook registration
├── hooks-handlers/
│   └── session-start.sh          # Loads config and injects credentials
├── config/
│   └── notion.conf               # Persistent configuration file
├── scripts/
│   ├── notion-setup.sh           # Configuration management script
│   └── export-md.sh              # MD file discovery helper
└── README.md                      # This file
```

## Setup Instructions

### Initial Setup

1. **Run the setup script**:
   ```bash
   bash ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/scripts/notion-setup.sh
   ```

2. **Enter your Notion database details when prompted**:
   - Notion Data Source ID
   - Database Name
   - Database URL
   - Default Category for exports

3. **Restart Claude Code**:
   The configuration will be loaded automatically on the next session start.

### Update Configuration

To update your Notion settings at any time:
```bash
bash ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/scripts/notion-setup.sh
```

## How to Use

### Export Single Markdown File

In any Claude Code session:
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

## How It Works

1. **SessionStart Hook**: Triggers when you start Claude Code
2. **Config Loading**: The `session-start.sh` script reads from `config/notion.conf`
3. **Environment Setup**: Configuration is exported as environment variables
4. **Context Injection**: Claude receives the credentials as additional context
5. **Export Ready**: You can immediately request markdown exports

## Configuration Storage

The plugin persists your configuration in:
```
~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/config/notion.conf
```

**Security Notes**:
- Config file has `600` permissions (owner read/write only)
- Notion credentials are stored locally, not transmitted
- Configuration persists across sessions

## Environment Variables

The following variables are exported to your Claude Code session:
- `NOTION_DATA_SOURCE_ID`: Your Notion database data source ID
- `NOTION_DATABASE_NAME`: Human-readable database name
- `NOTION_DATABASE_URL`: Full URL to your Notion database
- `NOTION_DEFAULT_CATEGORY`: Default category for new pages

## Verification

To verify the plugin is working:

1. **Check Installation**:
   ```bash
   ls -la ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/
   ```

2. **Test Hook Output**:
   ```bash
   ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/hooks-handlers/session-start.sh
   ```
   Should output JSON with Notion configuration.

3. **Start New Session**:
   ```bash
   cd /your/project
   claude
   ```
   Ask: "What's my Notion data source ID?"
   Claude should display your configured ID.

## Enable/Disable

### Enable (Default)
Plugin is enabled by default when installed at:
```
~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin/
```

### Disable
Rename the directory:
```bash
mv ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin \
   ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin.disabled
```

### Re-enable
```bash
mv ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin.disabled \
   ~/.claude/plugins/marketplaces/custom-plugins/inject-credentials-plugin
```

## Dependencies

- **Required**: Official Notion plugin (`Notion@claude-plugins-official`)
- **Claude Code Version**: >= 0.1.0

## Troubleshooting

**Plugin not loading?**
- Check file permissions: `session-start.sh` must be executable
- Verify `config/notion.conf` exists and is readable
- Check Claude Code logs for hook errors

**Configuration not loading?**
- Run setup script to create config: `bash scripts/notion-setup.sh`
- Verify config file has content: `cat config/notion.conf`
- Check file permissions: `ls -la config/notion.conf`

**Exports failing?**
- Ensure official Notion plugin is installed: `/plugin`
- Verify you're authenticated to Notion
- Check the data source ID is correct: run setup script
- Verify environment variables are set: `echo $NOTION_DATA_SOURCE_ID`

## Author

Muhammad Rizki Afdolli

## Version

2.0.0 - Persistent configuration system

---

**Last Updated**: 2026-02-16
