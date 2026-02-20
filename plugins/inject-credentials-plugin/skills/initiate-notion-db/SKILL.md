---
name: initiate-notion-db
description: Inject and persist Notion credentials for Claude Code plugin access
allowed-tools:
  - Read
  - Glob
  - Bash(mkdir *)
  - Bash(chmod *)
  - Write(~/.claude/plugins/cache/custom-plugins/inject-credentials-plugin/**/config/notion.conf)
---

You are handling the Notion database credential setup for the inject-credentials-plugin. Act immediately — do not explain the plugin or show documentation. Follow these steps in order:

## Step 1 — Check Existing Config

Check config paths for an existing `notion.conf`:
- `~/.claude/plugins/cache/custom-plugins/inject-credentials-plugin/*/config/notion.conf`

If a config exists:
- Read it and display the current values. Mask `NOTION_DATA_SOURCE_ID` to show only the first 8 and last 4 characters (e.g. `12345678...abcd`).
- Ask the user: "Configuration already exists. Do you want to update it?"
- If they say no, stop and confirm nothing was changed.
- If they say yes, proceed to Step 2.

If no config exists, proceed directly to Step 2.

## Step 2 — Collect Credentials

Ask the user for these six values in a single message (not one at a time):

1. **Notion Data Source ID** *(required)* — the database data source ID
2. **Database Name** *(required)* — human-readable name (e.g. "Main Notes")
3. **Database URL** *(required)* — must start with `https://www.notion.so/`
4. **Default Category** *(optional, default: "Learning Engineering")* — category tag for new exported pages
5. **Title Property Name** *(optional, default: "title")* — the exact property name used as the page title in this database (e.g. "Doc name", "Name", "Title")
6. **Category Options** *(optional)* — comma-separated list of all available category values in this database (e.g. "Claude Code, Side Project, Finance, Learning Engineering")

Validate before proceeding:
- Data Source ID must not be empty
- Database URL must start with `https://`

If validation fails, tell the user what's wrong and ask them to correct it.

## Step 3 — Write Config Files

Create the config directory if it doesn't exist, then write the config to **both** paths:

**Path (cache — runtime):**
Find the actual version directory under `~/.claude/plugins/cache/custom-plugins/inject-credentials-plugin/` and write to `<version>/config/notion.conf`.

Config file format (use quotes around values):
```
# Notion Configuration
# Generated on <current datetime>
NOTION_DATA_SOURCE_ID="<value>"
NOTION_DATABASE_NAME="<value>"
NOTION_DATABASE_URL="<value>"
NOTION_DEFAULT_CATEGORY="<value>"
NOTION_TITLE_PROPERTY="<value or 'title' if not provided>"
NOTION_CATEGORY_OPTIONS="<comma-separated list or empty if not provided>"
```

## Step 4 — Set Permissions

Run `chmod 600` on both config files so only the owner can read/write them.

## Step 5 — Confirm

Tell the user:
- Config saved to both paths
- Data Source ID (masked: first 8 + last 4 chars)
- Database name and default category
- Title property name and category options (if provided)
- "Restart Claude Code for the credentials to be injected on the next session start."