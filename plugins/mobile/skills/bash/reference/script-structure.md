# Script Structure

## Table of Contents
- [Shebang and Options](#shebang-and-options)
- [Script Template](#script-template)

## Shebang and Options

```bash
#!/usr/bin/env bash
# Use bash-specific features, not sh
# Always use 'bash' not 'sh' for bash scripts

# Set strict error handling at the top
set -euo pipefail
# -e: Exit on error
# -u: Exit on undefined variable
# -o pipefail: Exit on pipe failure
```

## Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# Script metadata
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="1.0.0"

# Configuration
readonly DEFAULT_TIMEOUT=30
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME}.log}"
DRY_RUN=0

# Logging functions
info() {
    echo "INFO: $*" >&2
}

success() {
    echo "SUCCESS: $*" >&2
}

warn() {
    echo "WARNING: $*" >&2
}

error() {
    echo "ERROR: $*" >&2
}

# Error handler
die() {
    echo "ERROR: $*" >&2
    exit 1
}

# Self-test function
test_script() {
    echo "Running self-tests..."

    # Syntax check
    bash -n "${BASH_SOURCE[0]}" || die "Syntax check failed"

    # ShellCheck (if available)
    if command -v shellcheck &> /dev/null; then
        shellcheck -x "${BASH_SOURCE[0]}" || die "ShellCheck failed"
    fi

    echo "All tests passed!"
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --test)
                test_script
                exit 0
                ;;
            --dry-run|-n)
                DRY_RUN=1
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
}

# Main function
main() {
    parse_args "$@"
    validate_prerequisites
    execute_task
}

# Run main only if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```
