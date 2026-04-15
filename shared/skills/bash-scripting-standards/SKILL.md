---
name: bash-scripting-standards
description: "Comprehensive bash scripting standards covering syntax, best practices, error handling, security, and ShellCheck compliance"
---

# Bash Scripting Standards

Expert-level guidelines for writing efficient, maintainable, and secure bash scripts following modern best practices and ShellCheck standards.

## MacOS Compatibility Requirement

**ALL scripts MUST be compatible with MacOS (BSD utilities) by default.**

MacOS uses BSD versions of common utilities (sed, grep, stat, etc.) which differ from GNU versions found on Linux. Scripts must either:
1. Use portable syntax that works on both BSD and GNU utilities
2. Detect the OS and use appropriate syntax
3. Document GNU utilities requirement and fail gracefully if not available

See the [MacOS Compatibility](#macos-compatibility) section for detailed requirements.

## CRITICAL RULE: Test After Every Change

**ALWAYS test your bash script after making ANY changes, no matter how small!**

Required testing steps:
1. Run `shellcheck -x script.sh` - Fix all warnings before proceeding
2. Run `bash -n script.sh` - Verify syntax is valid
3. Test with `--dry-run` flag (if your script supports it)
4. Test with valid inputs (happy path)
5. Test with invalid inputs (error cases)
6. Test interruption handling (Ctrl+C cleanup)

Whenever you update any script file, you must run linting (for example, `shellcheck`) immediately and resolve every reported issue before the change is considered complete. Do not postpone or ignore lint findings.

Use the built-in `--test` flag: `./script.sh --test`

See the [Testing and Debugging](#testing-and-debugging) section for comprehensive testing guidance.

## Script Structure

### Shebang and Options
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

### Script Template
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

## Syntax and Style

### Variables
```bash
# Use lowercase for local variables
local temp_file="/tmp/data.txt"
local user_name="john"

# Use UPPERCASE for constants and environment variables
readonly MAX_RETRIES=3
readonly CONFIG_DIR="/etc/myapp"

# IMPORTANT: Never declare unused variables
# BAD - unused variable
local unused_var="value"  # This will trigger ShellCheck SC2034

# GOOD - only declare variables you actually use
local config_file="${CONFIG_FILE:-$HOME/.config}"
if [[ -f "${config_file}" ]]; then
    source "${config_file}"
fi

# CRITICAL: Declare and assign separately (SC2155)
# BAD - masks return value of command
local result=$(command)  # If command fails, 'local' returns 0, masking the error

# GOOD - declare and assign separately to preserve exit codes
local result
result=$(command)  # Now if command fails, the error is properly caught

# BAD - multiple issues
local output=$(curl -f "https://api.example.com/data")

# GOOD - proper error handling
local output
output=$(curl -f "https://api.example.com/data")

# Always quote variables to prevent word splitting
echo "${variable}"
echo "${array[@]}"

# Use ${var} instead of $var for clarity
local file_path="${HOME}/.config/app"

# Default values
local timeout="${TIMEOUT:-30}"
local config_file="${CONFIG_FILE:-$HOME/.config}"

# Variable expansion with modification
local filename="${path##*/}"  # basename
local directory="${path%/*}"  # dirname
local extension="${file##*.}" # file extension
local basename="${file%.*}"   # filename without extension
```

### Functions
```bash
# Function names: lowercase with underscores
# Document complex functions
function_name() {
    local param1="$1"
    local param2="${2:-default}"
    
    # Function body
    echo "Processing: ${param1}"
    
    # Return status (0 = success, non-zero = failure)
    return 0
}

# Use local variables in functions
calculate_sum() {
    local a="$1"
    local b="$2"
    local result=$((a + b))
    echo "${result}"
}

# Check required arguments
process_file() {
    local file="$1"
    
    if [[ $# -lt 1 ]]; then
        echo "Error: Missing required argument" >&2
        return 1
    fi
    
    # Process file
}

# IMPORTANT: Declare and assign separately (SC2155)
get_user_info() {
    # BAD - masks curl's exit code
    local user_data=$(curl -f "https://api.example.com/user")
    
    # GOOD - properly handles errors
    local user_data
    user_data=$(curl -f "https://api.example.com/user") || {
        echo "Failed to fetch user data" >&2
        return 1
    }
    
    echo "${user_data}"
}
```

### Conditionals
```bash
# Use [[ ]] instead of [ ] (bash-specific, more features)
if [[ -f "${file}" ]]; then
    echo "File exists"
fi

# String comparisons
if [[ "${var}" == "value" ]]; then
    echo "Match"
fi

# Numeric comparisons
if [[ ${count} -gt 10 ]]; then
    echo "Greater than 10"
fi

# Multiple conditions
if [[ -f "${file}" && -r "${file}" ]]; then
    echo "File exists and is readable"
fi

# Pattern matching
if [[ "${filename}" == *.txt ]]; then
    echo "Text file"
fi

# Regex matching
if [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Valid version format"
fi

# Check if variable is empty
if [[ -z "${var}" ]]; then
    echo "Variable is empty"
fi

# Check if variable is not empty
if [[ -n "${var}" ]]; then
    echo "Variable is not empty"
fi
```

### Loops
```bash
# For loop with range
for i in {1..10}; do
    echo "Number: ${i}"
done

# For loop with array
local files=("file1.txt" "file2.txt" "file3.txt")
for file in "${files[@]}"; do
    process_file "${file}"
done

# For loop with command output (prefer while read)
while IFS= read -r line; do
    echo "Line: ${line}"
done < "${file}"

# While loop
local count=0
while [[ ${count} -lt 10 ]]; do
    echo "Count: ${count}"
    ((count++))
done

# Loop over files (safe for filenames with spaces)
while IFS= read -r -d '' file; do
    echo "Processing: ${file}"
done < <(find . -type f -name "*.txt" -print0)
```

### Arrays
```bash
# Declare array
local my_array=()
local files=("file1.txt" "file2.txt" "file3.txt")

# Add to array
my_array+=("new_item")

# Access elements
echo "${my_array[0]}"
echo "${my_array[@]}"  # All elements
echo "${#my_array[@]}" # Array length

# Iterate over array
for item in "${my_array[@]}"; do
    echo "${item}"
done

# Associative arrays (bash 4+)
declare -A config
config[host]="localhost"
config[port]="8080"

# Access associative array
echo "${config[host]}"
for key in "${!config[@]}"; do
    echo "${key}: ${config[${key}]}"
done
```

## Error Handling

### Exit Codes
```bash
# Standard exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1
readonly EXIT_INVALID_ARGUMENT=2
readonly EXIT_CONFIG_ERROR=3

# Exit with error message
die() {
    echo "ERROR: $*" >&2
    exit "${EXIT_FAILURE}"
}

# Usage example
[[ -f "${config_file}" ]] || die "Config file not found: ${config_file}"
```

### Trap and Cleanup
```bash
# Cleanup function
cleanup() {
    local exit_code=$?
    
    # Remove temporary files
    [[ -n "${temp_file:-}" ]] && rm -f "${temp_file}"
    [[ -n "${temp_dir:-}" ]] && rm -rf "${temp_dir}"
    
    # Log cleanup
    echo "Cleanup completed with exit code: ${exit_code}" >&2
    
    exit "${exit_code}"
}

# Set trap for cleanup on exit
trap cleanup EXIT INT TERM

# Create temp file/directory safely
temp_file="$(mktemp)"
temp_dir="$(mktemp -d)"
```

### Error Messages
```bash
# Write errors to stderr
echo "Error: Something went wrong" >&2

# Error with function name and line number
error() {
    echo "ERROR in ${FUNCNAME[1]} (line ${BASH_LINENO[0]}): $*" >&2
}

# Warning message
warn() {
    echo "WARNING: $*" >&2
}

# Info message
info() {
    echo "INFO: $*"
}

# Debug message (only if DEBUG is set)
debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "DEBUG: $*" >&2
    fi
}

```

## Command Execution

### Running Commands
```bash
# Capture output and exit code (SC2155 compliant)
# ALWAYS declare and assign separately when using command substitution
local output
if output=$(command 2>&1); then
    echo "Success: ${output}"
else
    echo "Failed: ${output}" >&2
    return 1
fi

# BAD - masks command's exit code
local result=$(git rev-parse HEAD)

# GOOD - preserves exit code
local result
result=$(git rev-parse HEAD)

# Check if command exists
if command -v git &> /dev/null; then
    echo "Git is installed"
else
    die "Git is required but not installed"
fi

# Run command with timeout
if timeout 30s long_running_command; then
    echo "Completed within timeout"
else
    echo "Command timed out" >&2
fi

# Suppress output
command &> /dev/null

# Redirect stderr to stdout (with proper declaration)
local output
output=$(command 2>&1)

# Redirect stdout and stderr separately
local output
output=$(command 2> error.log)
```

### Pipelines
```bash
# Use pipefail to catch errors in pipes
set -o pipefail

# Example pipeline
cat file.txt | grep "pattern" | sort | uniq > output.txt

# Check pipeline status
if echo "data" | grep -q "pattern"; then
    echo "Pattern found"
fi

# Process command output line by line
command | while IFS= read -r line; do
    process_line "${line}"
done
```

## Input/Output

### Reading Input
```bash
# Read user input
read -r -p "Enter your name: " user_name

# Read password (no echo)
read -r -s -p "Enter password: " password
echo  # New line after password

# Read with timeout
if read -r -t 10 -p "Enter value (10s timeout): " value; then
    echo "You entered: ${value}"
else
    echo "Timeout or error"
fi

# Read from file
while IFS= read -r line; do
    echo "Line: ${line}"
done < "${input_file}"

# Read CSV
while IFS=, read -r col1 col2 col3; do
    echo "Column 1: ${col1}, Column 2: ${col2}"
done < data.csv
```

### Output Formatting
```bash
# Printf for formatted output
printf "%-20s %10s\n" "Name" "Value"
printf "%-20s %10d\n" "Count" 42

# Here document
cat <<EOF
This is a multi-line
text block that can include
variables: ${variable}
EOF

# Here string
grep "pattern" <<< "${text}"
```

## Argument Parsing

### Simple Arguments
```bash
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -f|--file)
                FILE="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                die "Unknown option: $1"
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Remaining positional arguments
    ARGS=("$@")
}
```

### Getopts (POSIX)
```bash
# For single-character options only
while getopts "hvf:o:" opt; do
    case ${opt} in
        h)
            show_help
            exit 0
            ;;
        v)
            VERBOSE=1
            ;;
        f)
            INPUT_FILE="${OPTARG}"
            ;;
        o)
            OUTPUT_FILE="${OPTARG}"
            ;;
        \?)
            die "Invalid option: -${OPTARG}"
            ;;
        :)
            die "Option -${OPTARG} requires an argument"
            ;;
    esac
done
shift $((OPTIND - 1))
```

## Security Best Practices

### Input Validation
```bash
# Validate input is not empty
validate_not_empty() {
    local value="$1"
    local name="$2"
    
    if [[ -z "${value}" ]]; then
        die "${name} cannot be empty"
    fi
}

# Validate file path (no path traversal)
validate_file_path() {
    local file="$1"
    
    # Check for path traversal
    if [[ "${file}" == *..* ]]; then
        die "Invalid file path: ${file}"
    fi
    
    # Resolve to absolute path (MacOS compatible)
    local abs_path
    if [[ -e "${file}" ]]; then
        if [[ -d "${file}" ]]; then
            abs_path="$(cd "${file}" && pwd)"
        else
            abs_path="$(cd "$(dirname "${file}")" && pwd)/$(basename "${file}")"
        fi
    else
        die "Invalid path: ${file} does not exist"
    fi
    
    echo "${abs_path}"
}

# Validate numeric input
validate_number() {
    local value="$1"
    
    if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
        die "Invalid number: ${value}"
    fi
}
```

### Safe File Operations
```bash
# Create file with restricted permissions
umask 077
touch "${secure_file}"

# Set specific permissions
chmod 600 "${secure_file}"

# Check file permissions (MacOS compatible)
get_file_perms() {
    local file="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        stat -f %A "${file}"  # MacOS (BSD stat)
    else
        stat -c %a "${file}"  # Linux (GNU stat)
    fi
}

if [[ $(get_file_perms "${file}") != "600" ]]; then
    die "File has incorrect permissions"
fi

# Atomic file write (write to temp, then move)
echo "data" > "${temp_file}"
chmod 644 "${temp_file}"
mv "${temp_file}" "${target_file}"
```

### Avoiding Command Injection
```bash
# BAD: Command injection risk
eval "command ${user_input}"  # NEVER do this

# GOOD: Use arrays for commands
local cmd=(git clone "${url}" "${destination}")
"${cmd[@]}"

# GOOD: Quote variables
rm -f "${user_provided_file}"  # Quoted

# GOOD: Validate before using
if [[ "${branch}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    git checkout "${branch}"
else
    die "Invalid branch name"
fi
```

## Performance Optimization

### Efficient Patterns
```bash
# Use built-in commands instead of external ones
# BAD
basename=$(basename "${path}")
dirname=$(dirname "${path}")

# GOOD
basename="${path##*/}"
dirname="${path%/*}"

# Use parameter expansion instead of sed (SC2001)
# BAD - spawns unnecessary subprocess
result=$(echo "${string}" | sed 's/foo/bar/')
result=$(echo "${string}" | sed 's/foo/bar/g')
result=$(echo "${string}" | sed 's|/path/to|/new/path|')

# GOOD - use parameter expansion (faster, more efficient)
result="${string/foo/bar}"        # Replace first occurrence
result="${string//foo/bar}"       # Replace all occurrences (global)
result="${string//\/path\/to/\/new\/path}"  # Path replacement

# More parameter expansion examples
text="hello world hello"
echo "${text/hello/hi}"           # "hi world hello" (first only)
echo "${text//hello/hi}"          # "hi world hi" (all occurrences)
echo "${text/#hello/hi}"          # "hi world hello" (start of string)
echo "${text/%hello/hi}"          # "hello world hi" (end of string)

# Case conversion (bash 4+)
upper="${string^^}"               # Convert to uppercase
lower="${string,,}"               # Convert to lowercase
capitalize="${string^}"           # Capitalize first letter

# When to use sed (complex patterns requiring regex)
# GOOD - sed is appropriate for complex regex patterns
result=$(echo "${string}" | sed 's/[0-9]\{3\}-[0-9]\{4\}/XXX-XXXX/g')
result=$(echo "${string}" | sed -E 's/^[[:space:]]+//')  # Complex whitespace handling

# Avoid unnecessary subshells
# BAD
files=$(ls | grep ".txt")

# GOOD
files=(*.txt)

# Use read instead of cat in loops
# BAD
for line in $(cat file.txt); do
    process "${line}"
done

# GOOD
while IFS= read -r line; do
    process "${line}"
done < file.txt

# Minimize fork/exec calls
# BAD
for file in *.txt; do
    cat "${file}" | grep "pattern"
done

# GOOD
grep "pattern" *.txt
```

## Testing and Debugging

### Self-Testing After Changes

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

### Implement Dry-Run Mode
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

### Test Checklist After Every Change
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

### Debug Mode
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

### Assertions
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

### Manual Testing Steps

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

## ShellCheck Compliance

This section follows the official [ShellCheck Wiki](https://www.shellcheck.net/wiki/) standards.

### Critical ShellCheck Rules

#### SC2034 - Unused Variables
**Never declare unused variables** - remove them instead of disabling the warning.
```bash
# BAD - triggers SC2034
local unused_var="value"

# GOOD - only declare variables you use
local config_file="${CONFIG_FILE:-$HOME/.config}"
if [[ -f "${config_file}" ]]; then
    source "${config_file}"
fi
```

#### SC2155 - Declare and Assign Separately
**Always declare and assign separately** when using command substitution to preserve exit codes.
```bash
# BAD - 'local' masks command's exit code
local result=$(command)

# GOOD - declare and assign separately
local result
result=$(command)

# Example with error handling
local output
if output=$(curl -f "https://api.example.com/data"); then
    echo "Success: ${output}"
else
    echo "Failed: ${output}" >&2
    return 1
fi
```

#### SC2001 - Use Parameter Expansion Instead of Sed
**Use parameter expansion** for simple substitutions (faster, no subprocess).
```bash
# BAD - spawns unnecessary subprocess
result=$(echo "${string}" | sed 's/foo/bar/')

# GOOD - use parameter expansion
result="${string/foo/bar}"        # First occurrence
result="${string//foo/bar}"       # All occurrences
result="${string/#prefix/}"       # Remove prefix
result="${string/%suffix/}"       # Remove suffix
```

#### SC2086 - Quote Variables
**Always quote variables** to prevent word splitting and globbing.
```bash
# BAD - word splitting and globbing
rm -f $file
echo $path

# GOOD - quoted
rm -f "${file}"
echo "${path}"

# Exception: when you explicitly want word splitting
# shellcheck disable=SC2086
options="--verbose --force"
command ${options}  # Intentional word splitting
```

#### SC2068 - Quote Array Expansions
**Quote array expansions** to preserve elements correctly.
```bash
# BAD - loses empty elements and spaces
function process_args() {
    other_command $@
}

# GOOD - preserves all elements
function process_args() {
    other_command "$@"
}

# Array expansion
files=(file1.txt "file with spaces.txt" file3.txt)
# BAD
process_files ${files[@]}
# GOOD
process_files "${files[@]}"
```

#### SC2046 - Quote Command Substitution
**Quote command substitution** to prevent word splitting.
```bash
# BAD - word splitting on spaces
for file in $(find . -name "*.txt"); do
    echo "${file}"
done

# GOOD - use while read with process substitution
while IFS= read -r -d '' file; do
    echo "${file}"
done < <(find . -name "*.txt" -print0)

# GOOD - quote if you must use for loop
for file in "$(get_single_file)"; do
    echo "${file}"
done
```

#### SC2006 - Use $() Instead of Backticks
**Use modern `$()` syntax** instead of legacy backticks.
```bash
# BAD - backticks are deprecated
output=`command`
result=`cat file.txt | grep pattern`

# GOOD - use $()
output=$(command)
result=$(grep pattern file.txt)
```

#### SC2162 - Read Without -r
**Always use `read -r`** to avoid backslash interpretation.
```bash
# BAD - backslashes are interpreted
read line

# GOOD - raw input preserved
read -r line

# Reading from file
while IFS= read -r line; do
    echo "${line}"
done < "${file}"
```

#### SC2181 - Check Exit Code Directly
**Check exit code directly** in if statement, not via `$?`.
```bash
# BAD - unnecessary $?
command
if [[ $? -eq 0 ]]; then
    echo "Success"
fi

# GOOD - check directly
if command; then
    echo "Success"
fi

# When you need the exit code multiple times
if command; then
    exit_code=$?
    echo "Command exited with: ${exit_code}"
fi
```

#### SC2154 - Variable Referenced But Not Assigned
**Ensure variables are assigned** before use, or set defaults.
```bash
# BAD - variable might not be set
echo "${undefined_var}"

# GOOD - check if set
if [[ -n "${var:-}" ]]; then
    echo "${var}"
fi

# GOOD - use default value
echo "${CONFIG_FILE:-/etc/default.conf}"

# GOOD - check environment variable
if [[ -z "${REQUIRED_VAR:-}" ]]; then
    die "REQUIRED_VAR must be set"
fi
```

#### SC2164 - Use cd || exit
**Check cd success** or use `cd || exit` to avoid running in wrong directory.
```bash
# BAD - continues if cd fails
cd /some/directory
rm -rf ./*  # DANGEROUS if cd failed!

# GOOD - exit on failure
cd /some/directory || exit 1
rm -rf ./*

# GOOD - die with message
cd /some/directory || die "Failed to change directory"

# GOOD - subshell for temporary directory change
(cd /some/directory && command)
```

#### SC2039 - POSIX Portability
**Use bash-specific features** only in bash scripts (with proper shebang).
```bash
# GOOD - bash shebang for bash features
#!/usr/bin/env bash
local var="value"  # 'local' is bash-specific

# If you need POSIX compliance
#!/bin/sh
# Don't use: local, [[]], arrays, etc.
```

### Common ShellCheck Directives
```bash
# Source external file
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"

# Dynamic source (can't be followed)
# shellcheck source=/dev/null
source "${dynamic_file}"

# Disable for specific cases (use sparingly)
# shellcheck disable=SC2086
# Multiple lines of code
# that need the warning disabled

# Multiple rules on one line
# shellcheck disable=SC2086,SC2154
command ${intentional_word_splitting} "${might_be_unset}"

# Disable for entire file (use very sparingly)
# shellcheck disable=SC2034

# AVOID: Don't disable SC2034, SC2155, SC2001
# Instead, fix the code to comply with best practices
```

### ShellCheck Best Practices Summary
Reference: [ShellCheck Wiki](https://www.shellcheck.net/wiki/)

**Critical Rules (Never Disable):**
- **SC2034** - Never declare unused variables
- **SC2155** - Always declare and assign separately
- **SC2001** - Use parameter expansion instead of sed for simple substitutions
- **SC2086** - Always quote variables to prevent word splitting
- **SC2068** - Quote array expansions: `"$@"` not `$@`
- **SC2046** - Quote command substitutions to prevent word splitting
- **SC2006** - Use `$()` instead of backticks
- **SC2162** - Use `read -r` to avoid backslash interpretation
- **SC2164** - Use `cd || exit` to check cd success

**Important Rules:**
- **SC2181** - Check exit code directly in if statement
- **SC2154** - Ensure variables are assigned before use
- **SC2039** - Use bash shebang for bash-specific features
- **SC2094** - Don't read and write the same file
- **SC2103** - Use subshell to avoid cd in main script
- **SC2035** - Use `./*` not `*` to prevent glob interpretation as options

**Best Practices:**
- Fix ShellCheck warnings rather than disabling them
- If you must disable, use `# shellcheck disable=SCXXXX` with explanation
- Run `shellcheck -x script.sh` before committing
- Use `shellcheck --severity=style` to catch even more issues

## MacOS Compatibility

### Overview

MacOS uses BSD versions of common Unix utilities, which have different syntax and behavior compared to GNU versions found on Linux. **All scripts must be tested on MacOS** or use portable syntax.

### OS Detection

```bash
# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Use in script
readonly OS_TYPE="$(detect_os)"

# Conditional logic based on OS
if [[ "${OS_TYPE}" == "macos" ]]; then
    # MacOS-specific code
    :
elif [[ "${OS_TYPE}" == "linux" ]]; then
    # Linux-specific code
    :
fi
```

### readlink - Get Absolute Path

**Problem**: `readlink -f` doesn't exist on MacOS BSD `readlink`.

```bash
# BAD - fails on MacOS
abs_path=$(readlink -f "${file}")

# GOOD - portable solution using pwd
get_abs_path() {
    local path="$1"
    
    # If path is already absolute, return as-is
    if [[ "${path}" == /* ]]; then
        echo "${path}"
        return 0
    fi
    
    # Handle relative paths
    if [[ -e "${path}" ]]; then
        if [[ -d "${path}" ]]; then
            (cd "${path}" && pwd)
        else
            (cd "$(dirname "${path}")" && pwd)/$(basename "${path}")
        fi
    else
        echo "Error: Path does not exist: ${path}" >&2
        return 1
    fi
}

# Usage
abs_path=$(get_abs_path "${relative_path}")

# Alternative: Check for GNU readlink (greadlink from coreutils)
get_abs_path_v2() {
    local path="$1"
    
    if command -v greadlink &> /dev/null; then
        # GNU readlink available (brew install coreutils)
        greadlink -f "${path}"
    elif command -v readlink &> /dev/null && readlink -f / &> /dev/null 2>&1; then
        # GNU readlink available as readlink
        readlink -f "${path}"
    else
        # Fallback for BSD readlink (MacOS)
        if [[ -d "${path}" ]]; then
            (cd "${path}" && pwd)
        else
            (cd "$(dirname "${path}")" && pwd)/$(basename "${path}")
        fi
    fi
}
```

### stat - File Information

**Problem**: `stat` has completely different syntax on MacOS vs Linux.

```bash
# BAD - Linux only
permissions=$(stat -c %a "${file}")
size=$(stat -c %s "${file}")

# BAD - MacOS only
permissions=$(stat -f %A "${file}")
size=$(stat -f %z "${file}")

# GOOD - portable solution
get_file_permissions() {
    local file="$1"
    
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # MacOS (BSD stat)
        stat -f %A "${file}"
    else
        # Linux (GNU stat)
        stat -c %a "${file}"
    fi
}

get_file_size() {
    local file="$1"
    
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # MacOS (BSD stat)
        stat -f %z "${file}"
    else
        # Linux (GNU stat)
        stat -c %s "${file}"
    fi
}

# Usage
permissions=$(get_file_permissions "${file}")
size=$(get_file_size "${file}")

# Alternative: Use portable commands
# For file size, use wc or ls
size=$(wc -c < "${file}" | tr -d ' ')
```

### sed - Stream Editor

**Problem**: BSD `sed` (MacOS) requires different syntax, especially for in-place editing.

```bash
# BAD - Linux only (GNU sed)
sed -i 's/foo/bar/g' file.txt

# BAD - MacOS only (BSD sed requires backup extension)
sed -i '' 's/foo/bar/g' file.txt

# GOOD - portable solution (avoid in-place editing)
sed 's/foo/bar/g' file.txt > file.txt.tmp && mv file.txt.tmp file.txt

# GOOD - cross-platform in-place editing
sed_inplace() {
    local pattern="$1"
    local file="$2"
    
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # MacOS (BSD sed) - requires backup extension, use empty string
        sed -i '' "${pattern}" "${file}"
    else
        # Linux (GNU sed)
        sed -i "${pattern}" "${file}"
    fi
}

# Usage
sed_inplace 's/foo/bar/g' file.txt

# BEST - avoid sed for simple substitutions (SC2001 compliance)
# Use parameter expansion instead (faster, portable, no subprocess)
result="${string//foo/bar}"  # Works everywhere
```

### date - Date/Time Commands

**Problem**: Different flags and format specifiers between GNU and BSD `date`.

```bash
# BAD - Linux only (GNU date)
yesterday=$(date -d "yesterday" +%Y-%m-%d)
timestamp=$(date -d "@${epoch}" +%Y-%m-%d)

# BAD - MacOS only (BSD date)
yesterday=$(date -v-1d +%Y-%m-%d)
timestamp=$(date -r "${epoch}" +%Y-%m-%d)

# GOOD - portable date formatting
get_yesterday() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # MacOS (BSD date)
        date -v-1d +%Y-%m-%d
    else
        # Linux (GNU date)
        date -d "yesterday" +%Y-%m-%d
    fi
}

epoch_to_date() {
    local epoch="$1"
    
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # MacOS (BSD date)
        date -r "${epoch}" +%Y-%m-%d
    else
        # Linux (GNU date)
        date -d "@${epoch}" +%Y-%m-%d
    fi
}

# Current timestamp (portable)
timestamp=$(date +%Y-%m-%d_%H-%M-%S)  # Works on both
```

### timeout - Command Timeout

**Problem**: `timeout` command doesn't exist on MacOS by default.

```bash
# BAD - Linux only
timeout 30s long_running_command

# GOOD - check if timeout exists or use alternative
run_with_timeout() {
    local timeout_duration="$1"
    shift
    local cmd=("$@")
    
    if command -v timeout &> /dev/null; then
        # GNU timeout available
        timeout "${timeout_duration}" "${cmd[@]}"
    elif command -v gtimeout &> /dev/null; then
        # GNU timeout from coreutils (brew install coreutils)
        gtimeout "${timeout_duration}" "${cmd[@]}"
    else
        # Fallback: Run without timeout on MacOS
        warn "timeout command not available, running without timeout"
        warn "Install coreutils: brew install coreutils"
        "${cmd[@]}"
    fi
}

# Usage
run_with_timeout 30s curl -f "https://api.example.com/data"

# Alternative: Implement timeout using background jobs
timeout_alternative() {
    local timeout_duration="$1"
    shift
    local cmd=("$@")
    
    # Run command in background
    "${cmd[@]}" &
    local pid=$!
    
    # Wait for command with timeout
    local count=0
    while kill -0 "${pid}" 2>/dev/null; do
        if [[ ${count} -ge ${timeout_duration} ]]; then
            kill -TERM "${pid}" 2>/dev/null
            sleep 1
            kill -KILL "${pid}" 2>/dev/null
            echo "Command timed out after ${timeout_duration}s" >&2
            return 124  # Same exit code as GNU timeout
        fi
        sleep 1
        ((count++))
    done
    
    # Get command exit code
    wait "${pid}"
}
```

### find - File Search

**Problem**: Minor differences in behavior and flags.

```bash
# Mostly portable, but be careful with:

# GOOD - Use -print0 with while read for files with spaces (works on both)
while IFS= read -r -d '' file; do
    echo "Processing: ${file}"
done < <(find . -type f -name "*.txt" -print0)

# Be careful with -regex (different regex flavors)
# BAD - may behave differently
find . -regex ".*\.txt"

# GOOD - use -name with wildcards (more portable)
find . -name "*.txt"

# GOOD - for complex patterns, pipe to grep
find . -type f | grep -E "pattern"
```

### grep - Pattern Matching

**Problem**: Some GNU extensions not available in BSD grep.

```bash
# These work on both:
grep -r "pattern" .           # Recursive search
grep -i "pattern" file.txt    # Case-insensitive
grep -v "pattern" file.txt    # Invert match
grep -E "regex" file.txt      # Extended regex

# Be careful with:
# -P (PCRE) - NOT available on MacOS BSD grep
# BAD - fails on MacOS
grep -P "(?<=foo)bar" file.txt

# GOOD - use -E for extended regex (portable)
grep -E "foobar" file.txt

# GOOD - use perl for PCRE if needed
perl -ne 'print if /(?<=foo)bar/' file.txt

# GOOD - document if GNU grep required
if ! grep --version 2>&1 | grep -q "GNU grep"; then
    die "This script requires GNU grep. Install it with: brew install grep"
fi
```

### Sort and Other Utilities

```bash
# Most basic utilities work the same on both platforms:
# - sort (mostly compatible)
# - uniq (compatible)
# - cut (compatible)
# - awk (compatible, but MacOS has older version)
# - tr (compatible)
# - wc (compatible)

# For awk, avoid GNU-specific features
# GOOD - portable awk
awk '{print $1}' file.txt
awk -F, '{print $2}' file.csv

# For advanced features, specify gawk if needed
if command -v gawk &> /dev/null; then
    gawk 'advanced_feature' file.txt
else
    awk 'basic_alternative' file.txt
fi
```

### Cross-Platform Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# Script metadata
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly OS_TYPE="$(uname -s)"

# Detect OS
is_macos() {
    [[ "${OS_TYPE}" == "Darwin" ]]
}

is_linux() {
    [[ "${OS_TYPE}" == "Linux" ]]
}

# Portable get absolute path
get_abs_path() {
    local path="$1"
    if [[ -d "${path}" ]]; then
        (cd "${path}" && pwd)
    else
        echo "$(cd "$(dirname "${path}")" && pwd)/$(basename "${path}")"
    fi
}

# Portable in-place sed
sed_inplace() {
    local pattern="$1"
    local file="$2"
    
    if is_macos; then
        sed -i '' "${pattern}" "${file}"
    else
        sed -i "${pattern}" "${file}"
    fi
}

# Portable file permissions
get_file_permissions() {
    local file="$1"
    
    if is_macos; then
        stat -f %A "${file}"
    else
        stat -c %a "${file}"
    fi
}

# Check for required commands
check_prerequisites() {
    local required_commands=(git curl)
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            die "Required command not found: ${cmd}"
        fi
    done
    
    # Warn about optional GNU tools on MacOS
    if is_macos; then
        if ! command -v greadlink &> /dev/null; then
            warn "greadlink not found. Install coreutils for better compatibility:"
            warn "  brew install coreutils"
        fi
    fi
}

main() {
    check_prerequisites
    # Your script logic here
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### MacOS Testing Checklist

Before committing scripts, test on MacOS:

- [ ] Test on MacOS (or use portable syntax)
- [ ] Avoid `readlink -f` (use portable alternative)
- [ ] Avoid `stat -c` (use `stat -f` on MacOS or portable function)
- [ ] Test `sed -i` with both BSD and GNU syntax
- [ ] Avoid `date -d` (use `date -v` on MacOS or portable function)
- [ ] Check if `timeout` is needed (not on MacOS by default)
- [ ] Avoid `grep -P` (PCRE not available on BSD grep)
- [ ] Use `#!/usr/bin/env bash` not `#!/bin/bash` (more portable)
- [ ] Test with bash 3.2+ (MacOS default is old bash due to GPL3 licensing)

### GNU Utilities on MacOS

If GNU utilities are required, document this and provide installation instructions:

```bash
# Check for GNU utilities
check_gnu_utils() {
    local missing_utils=()
    
    # Check for GNU versions
    if ! command -v greadlink &> /dev/null; then
        missing_utils+=("greadlink")
    fi
    
    if ! command -v gsed &> /dev/null; then
        missing_utils+=("gsed")
    fi
    
    if [[ ${#missing_utils[@]} -gt 0 ]]; then
        error "This script requires GNU utilities on MacOS:"
        for util in "${missing_utils[@]}"; do
            echo "  - ${util}" >&2
        done
        echo "" >&2
        echo "Install with:" >&2
        echo "  brew install coreutils" >&2
        echo "  brew install gnu-sed" >&2
        return 1
    fi
    
    return 0
}

# Use GNU versions if available
if command -v greadlink &> /dev/null; then
    alias readlink=greadlink
fi

if command -v gsed &> /dev/null; then
    alias sed=gsed
fi
```

### Best Practices for Portability

1. **Test on MacOS**: Always test scripts on MacOS or use portable syntax
2. **Use parameter expansion**: Avoid `sed` for simple substitutions (SC2001)
3. **Use portable commands**: Prefer `cd && pwd` over `readlink -f`
4. **Detect OS**: Use OS detection for platform-specific code
5. **Document requirements**: If GNU tools required, document and check
6. **Fail gracefully**: Provide helpful error messages for missing tools
7. **Use bash 3.2+ compatible syntax**: MacOS ships with old bash
8. **Avoid bashisms in POSIX scripts**: Use `#!/usr/bin/env bash` for bash features

## Documentation

### Script Header
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

### Function Documentation
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

## Common Patterns

### Retry Logic
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

### Progress Indicator
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

### Parallel Execution
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

## Summary Checklist

### Before Committing Changes
- [ ] **ALWAYS test the script after ANY changes** (see Testing section)
- [ ] **Test on MacOS** or use portable syntax (see [MacOS Compatibility](#macos-compatibility))
- [ ] Run `shellcheck -x script.sh` and fix all warnings
- [ ] Run `bash -n script.sh` to check syntax
- [ ] Test with `--dry-run` if available
- [ ] Test happy path with valid inputs
- [ ] Test error cases (missing files, invalid inputs, etc.)
- [ ] Test Ctrl+C interruption (cleanup works)

### Code Standards

**ShellCheck Compliance (see [ShellCheck Wiki](https://www.shellcheck.net/wiki/)):**
- [ ] Use `#!/usr/bin/env bash` shebang
- [ ] Set `set -euo pipefail` for error handling
- [ ] **SC2034** - Never declare unused variables
- [ ] **SC2155** - Declare and assign separately for command substitution
- [ ] **SC2001** - Use parameter expansion instead of sed for simple substitutions
- [ ] **SC2086** - Quote all variables: `"${var}"`
- [ ] **SC2068** - Quote array expansions: `"$@"` not `$@`
- [ ] **SC2046** - Quote command substitutions to prevent word splitting
- [ ] **SC2006** - Use `$()` instead of backticks
- [ ] **SC2162** - Use `read -r` to avoid backslash interpretation
- [ ] **SC2164** - Use `cd || exit` to check cd success
- [ ] **SC2181** - Check exit code directly, not via `$?`
- [ ] **SC2154** - Ensure variables are assigned before use

**General Standards:**
- [ ] Use `[[ ]]` for conditionals
- [ ] Use `local` for function variables
- [ ] Use `readonly` for constants
- [ ] Implement trap cleanup for temp files
- [ ] Validate all inputs
- [ ] Write errors to stderr: `>&2`
- [ ] Use meaningful exit codes
- [ ] **Do not use emoji or ANSI color codes in log output** (plain text only)
- [ ] Add proper documentation
- [ ] Handle edge cases (empty inputs, missing files)
- [ ] Use arrays for lists, not strings
- [ ] Avoid eval and command injection risks
- [ ] **Always implement `--dry-run` option** for destructive operations
- [ ] **Always implement `--test` option** (syntax check + ShellCheck)
- [ ] Add `--help` option with usage information

**MacOS Compatibility (see [MacOS Compatibility](#macos-compatibility)):**
- [ ] Avoid `readlink -f` (use portable `cd && pwd` alternative)
- [ ] Avoid `stat -c` (use `stat -f` on MacOS or portable function)
- [ ] Use portable `sed -i` syntax (BSD requires `-i ''`)
- [ ] Avoid `date -d` (use `date -v` on MacOS or portable function)
- [ ] Avoid `timeout` (not available on MacOS by default)
- [ ] Avoid `grep -P` (PCRE not available in BSD grep)
- [ ] Use `#!/usr/bin/env bash` not `#!/bin/bash` (more portable)
- [ ] Test with bash 3.2+ (MacOS default is old bash)
