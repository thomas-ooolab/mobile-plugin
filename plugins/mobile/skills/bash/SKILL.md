---
name: bash
description: "Bash scripting standards covering syntax, error handling, security, and ShellCheck compliance. Use when writing or reviewing shell scripts, CI/CD bash automation, or Fastlane scripts in this project."
---

# Bash Scripting Standards

Expert-level guidelines for writing efficient, maintainable, and secure bash scripts following modern best practices and ShellCheck standards.

## MacOS Compatibility Requirement

**ALL scripts MUST be compatible with MacOS (BSD utilities) by default.**

MacOS uses BSD versions of common utilities (sed, grep, stat, etc.) which differ from GNU versions found on Linux. Scripts must either:
1. Use portable syntax that works on both BSD and GNU utilities
2. Detect the OS and use appropriate syntax
3. Document GNU utilities requirement and fail gracefully if not available

See [reference/shellcheck-macos.md](reference/shellcheck-macos.md) for detailed requirements.

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

See [reference/patterns.md](reference/patterns.md) for comprehensive testing guidance.

## Reference

| Topic | File |
|-------|------|
| Script structure and template | [reference/script-structure.md](reference/script-structure.md) |
| Syntax and style (variables, functions, loops, arrays) | [reference/syntax-style.md](reference/syntax-style.md) |
| Error handling, commands, I/O, argument parsing | [reference/error-handling.md](reference/error-handling.md) |
| Security best practices and performance optimization | [reference/security.md](reference/security.md) |
| ShellCheck compliance and macOS compatibility | [reference/shellcheck-macos.md](reference/shellcheck-macos.md) |
| Testing, debugging, documentation, and common patterns | [reference/patterns.md](reference/patterns.md) |

## Summary Checklist

### Before Committing Changes
- [ ] **ALWAYS test the script after ANY changes** (see [Testing](reference/patterns.md))
- [ ] **Test on MacOS** or use portable syntax (see [MacOS Compatibility](reference/shellcheck-macos.md))
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

**MacOS Compatibility (see [MacOS Compatibility](reference/shellcheck-macos.md)):**
- [ ] Avoid `readlink -f` (use portable `cd && pwd` alternative)
- [ ] Avoid `stat -c` (use `stat -f` on MacOS or portable function)
- [ ] Use portable `sed -i` syntax (BSD requires `-i ''`)
- [ ] Avoid `date -d` (use `date -v` on MacOS or portable function)
- [ ] Avoid `timeout` (not available on MacOS by default)
- [ ] Avoid `grep -P` (PCRE not available in BSD grep)
- [ ] Use `#!/usr/bin/env bash` not `#!/bin/bash` (more portable)
- [ ] Test with bash 3.2+ (MacOS default is old bash)
