# ShellCheck Compliance and MacOS Compatibility

## Table of Contents
- [Critical ShellCheck Rules](#critical-shellcheck-rules)
- [Common ShellCheck Directives](#common-shellcheck-directives)
- [ShellCheck Best Practices Summary](#shellcheck-best-practices-summary)
- [MacOS Compatibility Overview](#macos-compatibility-overview)
- [OS Detection](#os-detection)
- [readlink - Get Absolute Path](#readlink---get-absolute-path)
- [stat - File Information](#stat---file-information)
- [sed - Stream Editor](#sed---stream-editor)
- [date - Date/Time Commands](#date---datetime-commands)
- [timeout - Command Timeout](#timeout---command-timeout)
- [find - File Search](#find---file-search)
- [grep - Pattern Matching](#grep---pattern-matching)
- [Sort and Other Utilities](#sort-and-other-utilities)
- [Cross-Platform Script Template](#cross-platform-script-template)
- [MacOS Testing Checklist](#macos-testing-checklist)
- [GNU Utilities on MacOS](#gnu-utilities-on-macos)
- [Best Practices for Portability](#best-practices-for-portability)

---

This section follows the official [ShellCheck Wiki](https://www.shellcheck.net/wiki/) standards.

## Critical ShellCheck Rules

### SC2034 - Unused Variables
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

### SC2155 - Declare and Assign Separately
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

### SC2001 - Use Parameter Expansion Instead of Sed
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

### SC2086 - Quote Variables
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

### SC2068 - Quote Array Expansions
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

### SC2046 - Quote Command Substitution
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

### SC2006 - Use $() Instead of Backticks
**Use modern `$()` syntax** instead of legacy backticks.
```bash
# BAD - backticks are deprecated
output=`command`
result=`cat file.txt | grep pattern`

# GOOD - use $()
output=$(command)
result=$(grep pattern file.txt)
```

### SC2162 - Read Without -r
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

### SC2181 - Check Exit Code Directly
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

### SC2154 - Variable Referenced But Not Assigned
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

### SC2164 - Use cd || exit
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

### SC2039 - POSIX Portability
**Use bash-specific features** only in bash scripts (with proper shebang).
```bash
# GOOD - bash shebang for bash features
#!/usr/bin/env bash
local var="value"  # 'local' is bash-specific

# If you need POSIX compliance
#!/bin/sh
# Don't use: local, [[]], arrays, etc.
```

## Common ShellCheck Directives

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

## ShellCheck Best Practices Summary

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

---

## MacOS Compatibility Overview

MacOS uses BSD versions of common Unix utilities, which have different syntax and behavior compared to GNU versions found on Linux. **All scripts must be tested on MacOS** or use portable syntax.

## OS Detection

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

## readlink - Get Absolute Path

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

## stat - File Information

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

## sed - Stream Editor

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

## date - Date/Time Commands

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

## timeout - Command Timeout

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

## find - File Search

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

## grep - Pattern Matching

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

## Sort and Other Utilities

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

## Cross-Platform Script Template

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

## MacOS Testing Checklist

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

## GNU Utilities on MacOS

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

## Best Practices for Portability

1. **Test on MacOS**: Always test scripts on MacOS or use portable syntax
2. **Use parameter expansion**: Avoid `sed` for simple substitutions (SC2001)
3. **Use portable commands**: Prefer `cd && pwd` over `readlink -f`
4. **Detect OS**: Use OS detection for platform-specific code
5. **Document requirements**: If GNU tools required, document and check
6. **Fail gracefully**: Provide helpful error messages for missing tools
7. **Use bash 3.2+ compatible syntax**: MacOS ships with old bash
8. **Avoid bashisms in POSIX scripts**: Use `#!/usr/bin/env bash` for bash features
