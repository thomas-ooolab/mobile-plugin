# Syntax and Style

## Table of Contents
- [Variables](#variables)
- [Functions](#functions)
- [Conditionals](#conditionals)
- [Loops](#loops)
- [Arrays](#arrays)

## Variables

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

## Functions

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

## Conditionals

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

## Loops

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

## Arrays

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
