#!/usr/bin/env bash
set -euo pipefail

# Usage: commit.sh <patch|minor|major>
# Bumps version in both plugin.json files and stages them.
# Prints the new version to stdout.

BUMP=${1:-patch}

CLAUDE_JSON="plugins/mobile/.claude-plugin/plugin.json"
CURSOR_JSON="plugins/mobile/.cursor-plugin/plugin.json"

current=$(grep -o '"version": "[^"]*"' "$CLAUDE_JSON" | grep -o '[0-9]*\.[0-9]*\.[0-9]*')

IFS='.' read -r major minor patch <<< "$current"

case "$BUMP" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
  *) echo "Unknown bump type: $BUMP. Use patch|minor|major." >&2; exit 1 ;;
esac

new_version="$major.$minor.$patch"

sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$new_version\"/" "$CLAUDE_JSON"
sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$new_version\"/" "$CURSOR_JSON"

git add "$CLAUDE_JSON" "$CURSOR_JSON"

echo "$new_version"
