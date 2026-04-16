# Error Handling, Commands, I/O, and Argument Parsing

## Table of Contents
- [Exit Codes](#exit-codes)
- [Trap and Cleanup](#trap-and-cleanup)
- [Error Messages](#error-messages)
- [Command Execution](#command-execution)
- [Pipelines](#pipelines)
- [Input/Output](#inputoutput)
- [Argument Parsing](#argument-parsing)

## Exit Codes

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

## Trap and Cleanup

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

## Error Messages

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

## Pipelines

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
