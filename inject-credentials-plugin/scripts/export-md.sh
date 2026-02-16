#!/bin/bash

# Markdown to Notion Export Helper Script
# This script helps identify markdown files for export to Notion

# Usage: ./export-md.sh [directory]

DIR="${1:-.}"

echo "=== Markdown Files in $DIR ==="
echo ""

# Find all markdown files
find "$DIR" -name "*.md" -type f | while read -r file; do
    # Get file size
    size=$(wc -c < "$file" | tr -d ' ')

    # Extract first heading if exists
    title=$(grep -m 1 "^# " "$file" | sed 's/^# //' || basename "$file" .md)

    echo "File: $file"
    echo "  Title: $title"
    echo "  Size: $size bytes"
    echo ""
done

echo "=== Instructions ==="
echo "To export these files to Notion, tell Claude:"
echo "  \"Export all markdown files from $DIR to Notion\""
echo ""
echo "Or for a specific file:"
echo "  \"Export [filename] to Notion\""
