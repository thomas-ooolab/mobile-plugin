#!/usr/bin/env bash
# Push workflow script
# This script formats code, generates a commit message from changes, commits, and pushes

set -euo pipefail

# Script metadata
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR="${_script_dir}"
_root_dir="$(cd "${SCRIPT_DIR}" && git rev-parse --show-toplevel 2>/dev/null)" || _root_dir="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly ROOT_DIR="${_root_dir}"

# Global flags
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

die() {
    error "$*"
    exit 1
}

# Run syntax check and shellcheck on this script
test_script() {
    local script
    script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    info "Running bash -n on ${script}..."
    bash -n "${script}"
    info "Running shellcheck on ${script}..."
    shellcheck -x "${script}"
    success "All checks passed"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        die "Not in a git repository"
    fi
}

# Step 1: Format code using melos. On failure, exit immediately (no commit/push).
should_format_code() {
    cd "${ROOT_DIR}" || die "Failed to change to root directory"

    # Collect paths that are about to be committed (unstaged + staged + untracked).
    # We gate formatting so we don't waste time when only non-Dart/Flutter-related files changed.
    local changed_files
    changed_files="$(
        {
            git diff --name-only
            git diff --cached --name-only
            git ls-files --others --exclude-standard
        } | sed '/^$/d' | sort -u
    )"

    [[ -z "${changed_files}" ]] && return 1

    local file
    while IFS= read -r file; do
        # Allowed directories:
        # - lib/
        # - test/
        # - packages/**/lib/
        # - packages/**/test/
        if [[ "${file}" == lib/* ]] || [[ "${file}" == test/* ]] || [[ "${file}" =~ ^packages/.*/lib/ ]] || [[ "${file}" =~ ^packages/.*/test/ ]]; then
            continue
        fi
        # If any changed path is outside the allowed directories, skip formatting.
        return 1
    done <<< "${changed_files}"

    return 0
}

format_code() {
    info "Formatting code with melos..."
    cd "${ROOT_DIR}" || die "Failed to change to root directory"

    if ! fvm dart run melos dart-format; then
        die "Code formatting failed. Fix the reported issues, then rerun the push command."
    fi

    success "Code formatting completed"
}

# Helper: get ticket ID from release-notes.txt (e.g. LOE-6144)
get_ticket_id() {
    cd "${ROOT_DIR}" || die "Failed to change to root directory"

    if [[ -f "release-notes.txt" ]]; then
        # Extract first LOE-XXXX style ticket ID if present
        grep -oE 'LOE-[0-9]+' release-notes.txt | head -n1 || true
    fi
}

# Step 2: Read commit message provided by the agent
# The message must be generated before running this script.
# Priority order:
#   1) -m/--message "your message" CLI argument
#   2) COMMIT_MESSAGE environment variable
get_commit_message() {
    cd "${ROOT_DIR}" || die "Failed to change to root directory"

    local msg="${COMMIT_MESSAGE:-}"

    # Simple arg parsing for -m/--message
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message)
                shift || die "-m/--message provided but no value given"
                msg="${1-}"
                ;;
        esac
        shift || break
    done

    if [[ -z "${msg}" ]]; then
        die "No commit message provided. Please ask the Cursor agent to generate a commit message and pass it via COMMIT_MESSAGE env var or -m/--message argument."
    fi

    # Enforce ticket ID from release-notes.txt if present
    local ticket_id
    ticket_id="$(get_ticket_id || true)"
    if [[ -n "${ticket_id}" && "${msg}" != *"${ticket_id}"* ]]; then
        die "Commit message must include ticket ID ${ticket_id} from release-notes.txt. Current message: \"${msg}\""
    fi

    echo "${msg}"
}

# Step 3: Stage, commit, and push
commit_and_push() {
    local commit_message="${1-}"
    if [[ -z "${commit_message}" ]]; then
        die "Internal error: commit_and_push() called without a commit message."
    fi
    info "Checking for changes to commit..."

    # Check if there are any changes
    if ! git diff --quiet --exit-code || ! git diff --cached --quiet --exit-code; then
        info "Staging changes..."
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            info "[dry-run] Would run: git add -A"
        else
            git add -A
        fi

        info "Committing with message: ${commit_message}"
        # Use message as-is; do not add --trailer (e.g. Signed-off-by)
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            info "[dry-run] Would run: git commit -m \"${commit_message}\""
        else
            git commit -m "${commit_message}" || die "Commit failed"
            success "Changes committed successfully"
        fi
    else
        info "No changes to commit"
    fi

    # Push to remote (set upstream if branch doesn't exist on remote)
    info "Pushing to remote..."
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        info "[dry-run] Would run: git push -u origin HEAD"
    else
        if git push -u origin HEAD; then
            success "Pushed to remote successfully"
        else
            warn "Push failed or no remote configured"
            exit 1
        fi
    fi
}

# Main execution (format_code exits the script on failure; steps below run only if format succeeds)
main() {
    # Parse global flags before passing remaining args to sub-functions
    local pass_args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run|-n)
                DRY_RUN=1
                ;;
            --test)
                test_script
                exit 0
                ;;
            *)
                pass_args+=("$1")
                ;;
        esac
        shift
    done

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        info "Dry-run mode enabled — no git commit or push will be performed"
    fi

    info "Starting commit workflow..."

    check_git_repo

    if should_format_code; then
        format_code || exit 1
    else
        info "Skipping melos dart-format (changes are outside lib/, test/, packages/**/lib/, packages/**/test/)"
    fi

    local commit_message
    commit_message=$(get_commit_message "${pass_args[@]}")
    commit_and_push "${commit_message}"

    success "Commit workflow completed successfully"
}

# Run main function
main "$@"
