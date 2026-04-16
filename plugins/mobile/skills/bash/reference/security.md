# Security and Performance

## Table of Contents
- [Input Validation](#input-validation)
- [Safe File Operations](#safe-file-operations)
- [Avoiding Command Injection](#avoiding-command-injection)
- [Performance Optimization](#performance-optimization)

## Input Validation

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

## Safe File Operations

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

## Avoiding Command Injection

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
