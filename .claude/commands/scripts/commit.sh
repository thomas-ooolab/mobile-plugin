#!/usr/bin/env bash
set -euo pipefail

# Usage: commit.sh <patch|minor|major> <commit message>
# Auto-detects staged change scope:
#   - All staged files under plugins/ → bumps plugin.json files
#   - Any staged file outside plugins/ → bumps marketplace.json files
# Then runs git commit with the provided message.

BUMP=${1:-patch}
MSG=${2:-}

if [[ -z "$MSG" ]]; then
  echo "Usage: commit.sh <patch|minor|major> <commit message>" >&2
  exit 1
fi

CLAUDE_JSON="plugins/mobile/.claude-plugin/plugin.json"
CURSOR_JSON="plugins/mobile/.cursor-plugin/plugin.json"
CLAUDE_MARKETPLACE=".claude-plugin/marketplace.json"
CURSOR_MARKETPLACE=".cursor-plugin/marketplace.json"

# Detect scope from staged files
plugins_only=true
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if [[ "$f" != plugins/* ]]; then
    plugins_only=false
    break
  fi
done < <(git diff --cached --name-only)

# Read current version from appropriate source
if [ "$plugins_only" = true ]; then
  current=$(grep -o '"version": "[^"]*"' "$CLAUDE_JSON" | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
else
  current=$(python3 -c "import json; print(json.load(open('$CLAUDE_MARKETPLACE'))['metadata']['version'])")
fi

IFS='.' read -r major minor patch <<< "$current"

case "$BUMP" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
  *) echo "Unknown bump type: $BUMP. Use patch|minor|major." >&2; exit 1 ;;
esac

new_version="$major.$minor.$patch"

if [ "$plugins_only" = true ]; then
  sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$new_version\"/" "$CLAUDE_JSON"
  sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$new_version\"/" "$CURSOR_JSON"
  git add "$CLAUDE_JSON" "$CURSOR_JSON"
else
  python3 -c "
import json
for path in ['$CLAUDE_MARKETPLACE', '$CURSOR_MARKETPLACE']:
    with open(path) as f:
        data = json.load(f)
    data['metadata']['version'] = '$new_version'
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
"
  git add "$CLAUDE_MARKETPLACE" "$CURSOR_MARKETPLACE"
fi

echo "$new_version"
git commit -m "$MSG"
git push
