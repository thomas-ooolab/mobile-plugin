#!/usr/bin/env bash
# Format edited Dart files if dart is available in the project
set -euo pipefail

FILE="${TOOL_INPUT_PATH:-}"

[[ "$FILE" == *.dart ]] || exit 0
command -v dart &>/dev/null || exit 0
[[ -f "$FILE" ]] || exit 0

dart format "$FILE"
