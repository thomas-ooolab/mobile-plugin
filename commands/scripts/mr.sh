#!/usr/bin/env bash
# MR workflow script
# This script creates a Merge Request on GitLab using the glab CLI

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

# Open URL in default browser (macOS: open, Linux: xdg-open)
open_url_in_browser() {
    local url="$1"
    if [[ -z "${url}" ]]; then
        return 1
    fi
    if [[ "$(uname -s)" == "Darwin" ]]; then
        open "${url}"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "${url}"
    else
        warn "Could not open browser (no 'open' or 'xdg-open')"
        return 1
    fi
}

# Check prerequisites
check_requirements() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        die "Not in a git repository"
    fi

    if ! command -v glab >/dev/null 2>&1; then
        die "glab CLI is not installed or not in PATH. See: https://gitlab.com/gitlab-org/cli"
    fi
}

get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || die "Failed to determine current branch"
}

# Get ticket ID from release-notes.txt (e.g. LOE-6144). Same logic as push.sh.
get_ticket_id() {
    cd "${ROOT_DIR}" || die "Failed to change to root directory"
    if [[ -f "release-notes.txt" ]]; then
        grep -oE 'LOE-[0-9]+' release-notes.txt | head -n1 || true
    fi
}

# Derive conventional type from branch name (e.g. feat/LOE-6156 -> feat, fix/LOE-123 -> fix).
# Falls back to "feat" if no known prefix.
get_type_from_branch() {
    local branch="$1"
    local prefix="${branch%%/*}"
    case "${prefix}" in
        feat|fix|refactor|test|ci|docs|chore|'!'|breaking) echo "${prefix}" ;;
        *) echo "feat" ;;
    esac
}

# Return value for get_default_target_branch (avoid echo for stdout)
_mr_target_branch=""

get_default_target_branch() {
    # Allow override via env var; otherwise rely on GitLab project's default branch
    if [[ -n "${MR_TARGET_BRANCH:-}" ]]; then
        _mr_target_branch="${MR_TARGET_BRANCH}"
    else
        _mr_target_branch=""
    fi
}

# Read MR description template from .gitlab/merge_request_templates/Default.md
# This template is always used as the MR description.
get_mr_template_content() {
    local template_path="${ROOT_DIR}/.gitlab/merge_request_templates/Default.md"

    if [[ -f "${template_path}" ]]; then
        cat "${template_path}"
    else
        die "MR template not found at ${template_path}. Expected Default.md to exist."
    fi
}

# Derive MR title / description
# When user provides a title (via -t/--title or MR_TITLE), the script generates the full MR title
# in conventional format: <type>: [TICKET-ID]: <description>
# (type from branch, ticket ID from release-notes.txt; same convention as push.md/push.sh)
parse_args_and_generate_metadata() {
    cd "${ROOT_DIR}" || die "Failed to change to root directory"

    local user_title="${MR_TITLE:-}"
    # Description must always come from the Default.md template
    local description
    local draft="${MR_DRAFT:-false}"
    # Default label is 'learningos'; can be overridden via MR_LABELS or -l/--label
    local labels="${MR_LABELS:-learningos}"

    # Simple CLI parsing:
    #   -t|--title "Title"   (user-provided title; will be wrapped in <type>: [TICKET-ID]: <title>)
    #   --draft
    #   -l|--label "label1,label2"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--title)
                shift || die "-t/--title provided but no value given"
                user_title="${1-}"
                ;;
            --draft)
                draft="true"
                ;;
            -l|--label)
                shift || die "-l/--label provided but no value given"
                labels="${1-}"
                ;;
            --dry-run|-n|--test)
                # Already handled by main; ignore here
                ;;
            *)
                warn "Unknown argument ignored: $1"
                ;;
        esac
        shift || break
    done

    local title
    local ticket_id
    ticket_id="$(get_ticket_id || true)"
    local branch
    branch="$(get_current_branch)"

    if [[ -n "${user_title}" ]]; then
        # User provided a title: generate full title in format <type>: [TICKET-ID]: <description>
        local type
        type="$(get_type_from_branch "${branch}")"
        if [[ -n "${ticket_id}" ]]; then
            if [[ "${user_title}" == *"${ticket_id}"* ]]; then
                # User title already contains ticket ID; use as-is (assume already formatted)
                title="${user_title}"
            else
                title="${type}: ${ticket_id}: ${user_title}"
            fi
        else
            title="${type}: ${user_title}"
        fi
        # Enforce ticket ID in title when release-notes.txt has one (same as push.sh)
        if [[ -n "${ticket_id}" && "${title}" != *"${ticket_id}"* ]]; then
            die "MR title must include ticket ID ${ticket_id} from release-notes.txt. Generated title: \"${title}\""
        fi
    else
        # No user title: fallback to last commit subject, then "MR: <branch>"
        title="$(git log -1 --pretty=%s 2>/dev/null || true)"
        if [[ -z "${title}" ]]; then
            title="MR: ${branch}"
        fi
    fi

    # Always load description from the MR template
    description="$(get_mr_template_content)"

    # Return via globals so we don't use echo for stdout
    _mr_parse_title="${title}"
    _mr_parse_description="${description}"
    _mr_parse_draft="${draft}"
    _mr_parse_labels="${labels}"
}

create_mr() {
    cd "${ROOT_DIR}" || die "Failed to change to root directory"

    parse_args_and_generate_metadata "$@"
    local title="${_mr_parse_title}"
    local description="${_mr_parse_description}"
    local draft="${_mr_parse_draft}"
    local labels="${_mr_parse_labels}"

    info "MR metadata:"
    info "  title: ${title}"
    info "  draft: ${draft}"
    info "  labels: ${labels}"

    local branch
    branch="$(get_current_branch)"

    info "Current branch: ${branch}"

    # Ensure branch is pushed
    info "Pushing branch to origin..."
    if ! git push -u origin "${branch}"; then
        die "Failed to push branch '${branch}' to origin"
    fi

    get_default_target_branch
    local target_branch="${_mr_target_branch}"

    info "Creating Merge Request on GitLab using glab..."

    # Build glab arguments
    local args=()
    args+=("mr" "create")
    args+=("--title" "${title}")
    args+=("--description" "${description}")

    if [[ -n "${target_branch}" ]]; then
        args+=("--target-branch" "${target_branch}")
    fi

    if [[ "${draft}" == "true" ]]; then
        args+=("--draft")
    fi

    if [[ -n "${labels}" ]]; then
        args+=("--label" "${labels}")
    fi

    # Non-interactive creation; prints MR URL on success
    args+=("-y")

    # Print the completed glab command
    local cmd_display=""
    for a in "${args[@]}"; do
        cmd_display+=" $(printf '%q' "$a")"
    done
    info "glab command: glab${cmd_display}"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        info "[dry-run] Would run: glab${cmd_display}"
        return 0
    fi

    local glab_output glab_exit
    glab_output=$(glab "${args[@]}" 2>&1)
    glab_exit=$?
    printf '%s\n' "${glab_output}"

    if [[ ${glab_exit} -eq 0 ]]; then
        success "Merge Request created successfully"
        local mr_url
        mr_url=$(printf '%s\n' "${glab_output}" | grep -oE 'https://[^[:space:]]+merge_requests/[0-9]+' | head -1)
        if [[ -n "${mr_url}" ]]; then
            info "MR URL: ${mr_url}"
            info "Opening MR in browser..."
            open_url_in_browser "${mr_url}"
        fi
    else
        die "Failed to create Merge Request with glab"
    fi
}

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
        info "Dry-run mode enabled — glab mr create and browser open will be skipped"
    fi

    info "Starting MR workflow..."

    check_requirements
    create_mr "${pass_args[@]}"

    success "MR workflow completed successfully"
}

main "$@"
