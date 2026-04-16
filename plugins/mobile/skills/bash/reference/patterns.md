# Testing, Documentation, and Common Patterns

## Table of Contents
- [Self-Testing After Changes](#self-testing-after-changes)
- [Implement Dry-Run Mode](#implement-dry-run-mode)
- [Test Checklist After Every Change](#test-checklist-after-every-change)
- [Debug Mode](#debug-mode)
- [Assertions](#assertions)
- [Manual Testing Steps](#manual-testing-steps)
- [Script Header Documentation](#script-header-documentation)
- [Function Documentation](#function-documentation)
- [Retry Logic](#retry-logic)
- [Progress Indicator](#progress-indicator)
- [Parallel Execution](#parallel-execution)

## Self-Testing After Changes

**CRITICAL: Always test your script after making ANY changes, no matter how small.**

```bash
# 1. Run ShellCheck FIRST (before execution)
shellcheck -x script.sh

# 2. Test with dry-run mode (if available)
./script.sh --dry-run

# 3. Test with sample data
./script.sh --test-mode test_data.txt

# 4. Test error conditions
./script.sh /nonexistent/path  # Should handle gracefully

# 5. Test with verbose mode for debugging
./script.sh --verbose

# 6. Test all flags and options
./script.sh --help
./script.sh -v -f input.txt -o output.txt
```

## Implement Dry-Run Mode

```bash
# Always provide a dry-run option for destructive operations
DRY_RUN=0

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run|-n)
                DRY_RUN=1
                shift
                ;;
            # ... other options
        esac
    done
}

# Use dry-run in destructive operations
delete_files() {
    local pattern="$1"
    
    if [[ ${DRY_RUN} -eq 1 ]]; then
        echo "[DRY RUN] Would delete: ${pattern}"
        find . -name "${pattern}" -type f
    else
        echo "Deleting: ${pattern}"
        find . -name "${pattern}" -type f -delete
    fi
}
```

## Test Checklist After Every Change

```bash
# Create a testing function
test_script() {
    echo "Running self-tests..."
    
    # Test 1: Syntax check
    bash -n "${SCRIPT_NAME}" || {
        echo "ERROR: Syntax check failed" >&2
        return 1
    }
    
    # Test 2: ShellCheck
    if command -v shellcheck &> /dev/null; then
        shellcheck -x "${SCRIPT_NAME}" || {
            echo "ERROR: ShellCheck failed" >&2
            return 1
        }
    fi
    
    # Test 3: Required commands exist
    local required_commands=(git curl jq)
    for cmd in "${required_commands[@]}"; do
        command -v "${cmd}" &> /dev/null || {
            echo "ERROR: Required command not found: ${cmd}" >&2
            return 1
        }
    done
    
    # Test 4: Run with test data
    echo "All tests passed!"
}

# Add test option to your script
if [[ "${1:-}" == "--test" ]]; then
    test_script
    exit $?
fi
```

## Debug Mode

```bash
# Enable debugging
set -x  # Print commands before execution
set -v  # Print input lines as read

# Debug function
debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Use in code
debug "Variable value: ${var}"
debug "Processing file: ${file}"

# Conditional debugging
[[ "${DEBUG:-0}" == "1" ]] && set -x
```

## Assertions

```bash
# Assert function exists
assert_command_exists() {
    local cmd="$1"
    command -v "${cmd}" &> /dev/null || die "Required command not found: ${cmd}"
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    [[ -f "${file}" ]] || die "Required file not found: ${file}"
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    [[ -d "${dir}" ]] || die "Required directory not found: ${dir}"
}

# Assert variable is set
assert_var_set() {
    local var_name="$1"
    local var_value="${!var_name}"
    [[ -n "${var_value}" ]] || die "Required variable not set: ${var_name}"
}
```

## Manual Testing Steps

After making changes, perform these tests:

1. **Syntax Check**: `bash -n script.sh`
2. **ShellCheck**: `shellcheck -x script.sh`
3. **Dry Run**: Test with `--dry-run` flag
4. **Happy Path**: Test with valid inputs
5. **Error Cases**: Test with:
   - Missing required arguments
   - Invalid file paths
   - Non-existent files
   - Empty inputs
   - Special characters in inputs
6. **Edge Cases**: Test boundary conditions
7. **Interruption**: Test Ctrl+C handling (trap cleanup)
8. **Different Environments**: Test on different systems if possible

## Script Header Documentation

```bash
#!/usr/bin/env bash
#
# Script Name: deploy.sh
# Description: Deploys application to production environment
# Author: John Doe <john@example.com>
# Version: 1.0.0
# Created: 2024-01-01
# Modified: 2024-01-15
#
# Usage: ./deploy.sh [OPTIONS] <environment>
#
# Options:
#   -h, --help          Show this help message
#   -v, --verbose       Enable verbose output
#   -d, --dry-run       Perform dry run without making changes
#   -f, --force         Force deployment without confirmation
#
# Examples:
#   ./deploy.sh production
#   ./deploy.sh --dry-run staging
#   ./deploy.sh -v -f production
#
# Dependencies:
#   - git
#   - docker
#   - kubectl
#
# Environment Variables:
#   DEPLOY_TOKEN        Authentication token for deployment
#   LOG_LEVEL          Logging level (default: info)
#

set -euo pipefail
```

## Function Documentation

```bash
# Deploys application to specified environment
#
# Arguments:
#   $1 - Environment name (staging|production)
#   $2 - Version to deploy
#
# Returns:
#   0 on success
#   1 on deployment failure
#
# Example:
#   deploy_application "production" "v1.2.3"
deploy_application() {
    local environment="$1"
    local version="$2"
    
    # Function implementation
}
```

## Retry Logic

```bash
retry() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local cmd=("$@")
    
    local attempt=1
    while [[ ${attempt} -le ${max_attempts} ]]; do
        if "${cmd[@]}"; then
            return 0
        fi
        
        echo "Attempt ${attempt}/${max_attempts} failed. Retrying in ${delay}s..." >&2
        sleep "${delay}"
        ((attempt++))
    done
    
    echo "All ${max_attempts} attempts failed" >&2
    return 1
}

# Usage
retry 3 5 curl -f "https://api.example.com/health"
```

## Progress Indicator

```bash
show_progress() {
    local pid="$1"
    local delay=0.1
    local spinstr='|/-\'
    
    while kill -0 "${pid}" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "${spinstr}"
        spinstr=${temp}${spinstr%"$temp"}
        sleep ${delay}
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Usage
long_running_command &
show_progress $!
wait $!
```

## Parallel Execution

```bash
# Run commands in parallel
parallel_execute() {
    local max_jobs="${1:-4}"
    local job_count=0
    
    while read -r item; do
        process_item "${item}" &
        
        ((job_count++))
        if [[ ${job_count} -ge ${max_jobs} ]]; then
            wait -n  # Wait for any job to finish
            ((job_count--))
        fi
    done < "${input_file}"
    
    wait  # Wait for remaining jobs
}
```
