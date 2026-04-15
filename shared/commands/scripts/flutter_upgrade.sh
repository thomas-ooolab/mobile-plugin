#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root and cd there so paths like ./ios and .gitlab-ci.yml work from any script location
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_root_dir="$(cd "${_script_dir}" && git rev-parse --show-toplevel 2>/dev/null)" || _root_dir="$(cd "${_script_dir}/../../.." && pwd)"
cd "${_root_dir}" || exit 1

# ============================================================================
# Global Variables
# ============================================================================

# Define variables for .gitlab-ci.yml
MAIN_GITLAB_CI_YML=".gitlab-ci.yml"

# Define common file and directory variables
README_FILE="README.md"
GEM_CACHE_DIR_NAME=".gem"
IOS_DIR="./ios"
ANDROID_DIR="./android"
IOS_PODFILE_LOCK="${IOS_DIR}/Podfile.lock"

# Ruby version to use
RUBY_VERSION="3.2.2"

# Global variables to be set by functions
TARGET_FLUTTER_VERSION=""
DART_VERSION=""
LATEST_BUNDLER_VERSION=""
COMPATIBLE_BUNDLER_VERSION=""
BACKUP_DIR=".upgrade_backup"
DRY_RUN=0

# ============================================================================
# Helper Functions
# ============================================================================

info() {
  echo "INFO: $*" >&2
}

success() {
  echo "SUCCESS: $*" >&2
}

warn() {
  echo "WARN: $*" >&2
}

error() {
  echo "ERROR: $*" >&2
}

progress() {
  echo "PROGRESS: $*" >&2
}

celebrate() {
  echo "SUCCESS: $*" >&2
}

# Function to print error and exit
function error_exit {
  error "$1"
  exit 1
}

# Function to run syntax and static checks on this script
function test_script {
  local script_path
  script_path="${BASH_SOURCE[0]}"
  echo "Running bash -n on ${script_path}..."
  bash -n "${script_path}"
  echo "Running shellcheck on ${script_path}..."
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -x "${script_path}"
  else
    warn "shellcheck not found, skipping."
  fi
  echo "SUCCESS: Script syntax checks passed."
}

# ============================================================================
# Check Required Commands
# ============================================================================

function check_required_commands {
  progress "Checking required commands..."
  
  # Check for fvm
  if ! command -v fvm >/dev/null 2>&1; then
    error "fvm is not installed."
    info "To install fvm, run:"
    info "  dart pub global activate fvm"
    info "Or, if you have Homebrew, you can run:"
    info "  brew tap leoafarias/fvm"
    info "  brew install fvm"
    error_exit "Please install fvm and re-run this script."
  fi
  
  # Check for yq
  if ! command -v yq >/dev/null 2>&1; then
    warn "yq is not installed. Attempting to install via Homebrew..."
    if ! command -v brew >/dev/null 2>&1; then
      info "Homebrew is not installed. Attempting to install Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Failed to install Homebrew. Please install Homebrew manually."
      # Add Homebrew to PATH for the current session (for Apple Silicon and Intel)
      if [[ -d "/opt/homebrew/bin" ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
      elif [[ -d "/usr/local/bin" ]]; then
        export PATH="/usr/local/bin:$PATH"
      fi
    fi
    brew install yq || error_exit "Failed to install yq via Homebrew."
  fi
  
  success "All required commands are available."
}

# ============================================================================
# Determine Flutter Version
# ============================================================================

function determine_flutter_version {
  progress "Determining Flutter version..."
  
  # Accept Flutter version as argument or prompt user, or use newest stable
  if [[ -z "$1" ]]; then
    read -rp "Enter the target Flutter version (leave blank for newest stable): " TARGET_FLUTTER_VERSION
    if [[ -z "$TARGET_FLUTTER_VERSION" ]]; then
      info "No version provided, fetching newest stable Flutter version..."
      # Get the newest stable version name (e.g. 3.22.0)
      TARGET_FLUTTER_VERSION=$(fvm releases | grep -E 'stable' | awk '{print $2}' | tail -n1)
      if [[ -z "$TARGET_FLUTTER_VERSION" ]]; then
        error_exit "Could not determine newest stable Flutter version."
      fi
    fi
  else
    TARGET_FLUTTER_VERSION="$1"
  fi

  info "Target Flutter version: $TARGET_FLUTTER_VERSION"

  # Use the target Flutter version in the project
  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "DRY RUN: would run fvm use $TARGET_FLUTTER_VERSION --skip-pub-get -f"
  else
    fvm use "$TARGET_FLUTTER_VERSION" --skip-pub-get -f
  fi

  # Precache the iOS dependencies for the target Flutter version
  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "DRY RUN: would run fvm flutter precache --ios -f"
  else
    fvm flutter precache --ios -f
  fi
  
  # Get the Dart version that comes with the target Flutter
  DART_VERSION=$(fvm flutter --version | grep -oE 'Dart [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}')
  if [[ -z "$DART_VERSION" ]]; then
    error_exit "Could not determine Dart version from Flutter."
  fi
  success "Dart version for Flutter $TARGET_FLUTTER_VERSION: $DART_VERSION"
}

# ============================================================================
# Update Pubspec Files
# ============================================================================

function update_pubspec_files {
  progress "Updating pubspec.yaml files..."

  local PUBSPEC CURRENT_FLUTTER_VERSION CURRENT_DART_VERSION TMP_PUBSPEC

  # Find all pubspec.yaml files (root and under /packages)
  while IFS= read -r PUBSPEC; do
    info "Processing $PUBSPEC..."

    # Get the current Flutter version from pubspec.yaml
    CURRENT_FLUTTER_VERSION=$(yq '.environment.flutter' "$PUBSPEC")

    if [[ "$CURRENT_FLUTTER_VERSION" != "null" && "$CURRENT_FLUTTER_VERSION" != "$TARGET_FLUTTER_VERSION" ]]; then
      progress "Updating Flutter version in $PUBSPEC..."
      TMP_PUBSPEC="${PUBSPEC}.tmp"

      awk -v flutter_version="$TARGET_FLUTTER_VERSION" '
        BEGIN { in_environment=0 }
        /^[[:space:]]*environment:/ { in_environment=1; print; next }
        in_environment && /^[[:space:]]*flutter:/ {
          sub(/flutter:[[:space:]]*[^[:space:]]*/, "flutter: " flutter_version)
          print
          next
        }
        in_environment && /^[^[:space:]]/ { in_environment=0 }
        { print }
      ' "$PUBSPEC" > "$TMP_PUBSPEC" && mv "$TMP_PUBSPEC" "$PUBSPEC"
    else
      info "Flutter version is up to date in $PUBSPEC."
    fi

    # Get the current Dart version from pubspec.yaml
    CURRENT_DART_VERSION=$(yq '.environment.sdk' "$PUBSPEC")

    if [[ "$CURRENT_DART_VERSION" != "$DART_VERSION" ]]; then
      progress "Updating Dart version in $PUBSPEC..."
      TMP_PUBSPEC="${PUBSPEC}.tmp"

      awk -v dart_version="$DART_VERSION" '
        BEGIN { in_environment=0 }
        /^[[:space:]]*environment:/ { in_environment=1; print; next }
        in_environment && /^[[:space:]]*sdk:/ {
          sub(/sdk:[[:space:]]*[^[:space:]]*/, "sdk: " dart_version)
          print
          next
        }
        in_environment && /^[^[:space:]]/ { in_environment=0 }
        { print }
      ' "$PUBSPEC" > "$TMP_PUBSPEC" && mv "$TMP_PUBSPEC" "$PUBSPEC"
    else
      info "Dart version is up to date in $PUBSPEC."
    fi
  done < <(find . -type f -name pubspec.yaml)

  fvm dart pub get --
  
  success "Pubspec files updated successfully."
}

# ============================================================================
# Upgrade Dependencies and Remove Carets
# ============================================================================

function upgrade_dependencies_and_remove_carets {
  progress "Upgrading dependencies to latest versions..."
  
  # Run dart pub upgrade --major-versions
  info "Running fvm dart pub upgrade --major-versions..."
  fvm dart pub upgrade --major-versions
  
  success "Dependencies upgraded."
  
  # Remove caret symbols from all pubspec.yaml files
  progress "Removing caret (^) symbols from dependency versions..."
  
  local files_updated=0
  local PUBSPEC
  while IFS= read -r PUBSPEC; do
    # Check if file contains caret symbols in dependencies
    if grep -q '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*\^' "$PUBSPEC"; then
      info "Removing carets in $PUBSPEC..."
      # Remove caret from dependency versions (e.g., "package: ^1.2.3" -> "package: 1.2.3")
      sed -i.bak 's/^\([[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*\)\^/\1/' "$PUBSPEC"
      rm -f "${PUBSPEC}.bak"
      files_updated=$((files_updated + 1))
    fi
  done < <(find . -type f -name pubspec.yaml)
  
  if [[ $files_updated -gt 0 ]]; then
    success "Removed carets from $files_updated pubspec.yaml file(s)."
    
    # Run pub get again to update lock files with fixed versions
    info "Updating pubspec.lock with fixed versions..."
    fvm dart pub get --
  else
    info "No caret symbols found in pubspec.yaml files."
  fi
  
  success "Dependencies now use fixed versions (no carets)."
}

# ============================================================================
# Update GitLab CI Flutter Version
# ============================================================================

function update_gitlab_ci_flutter_version {
  progress "Updating GitLab CI Flutter version..."
  
  # Update FLUTTER_VERSION value in .gitlab-ci.yml
  if [[ -f "$MAIN_GITLAB_CI_YML" ]]; then
    info "Updating variables.FLUTTER_VERSION.value in $MAIN_GITLAB_CI_YML..."
    local TMP_CI_YML="${MAIN_GITLAB_CI_YML}.tmp"
    
    awk -v flutter_version="$TARGET_FLUTTER_VERSION" '
      BEGIN { in_variables=0 }
      /^[[:space:]]*variables:/ { in_variables=1; print; next }
      in_variables && /^[[:space:]]*FLUTTER_VERSION:/ {
        print $0
        getline
        while ($0 ~ /^[[:space:]]*value:/) getline
        print "    value: '\''" flutter_version "'\''"
        print "    expand: false"
        next
      }
      in_variables && /^[^[:space:]]/ { in_variables=0 }
      { print }
    ' "$MAIN_GITLAB_CI_YML" > "$TMP_CI_YML" && mv "$TMP_CI_YML" "$MAIN_GITLAB_CI_YML"
    success "GitLab CI Flutter version updated."
  else
    warn "$MAIN_GITLAB_CI_YML not found, skipping FLUTTER_VERSION update."
  fi
}

# ============================================================================
# Update README Flutter Version
# ============================================================================

function update_readme_flutter_version {
  progress "Updating README.md Flutter version..."
  
  # Update Flutter version in README.md
  if [[ -f "$README_FILE" ]]; then
    info "Updating Flutter version in $README_FILE to $TARGET_FLUTTER_VERSION..."
    local TMP_README="${README_FILE}.tmp"
    
    # Update the Flutter version in README.md
    # This will replace the line containing "- [Flutter](https://docs.flutter.dev/get-started/install/macos): v" with the new version
    awk -v flutter_version="$TARGET_FLUTTER_VERSION" '
      /- \[Flutter\]\(https:\/\/docs\.flutter\.dev\/get-started\/install\/macos\): v[0-9]+\.[0-9]+\.[0-9]+/ {
        sub(/v[0-9]+\.[0-9]+\.[0-9]+/, "v" flutter_version)
      }
      { print }
    ' "$README_FILE" > "$TMP_README" && mv "$TMP_README" "$README_FILE"
    
    # Remove trailing newline if it exists
    perl -pi -e 'chomp if eof' "$README_FILE"
    
    success "Successfully updated Flutter version in $README_FILE to $TARGET_FLUTTER_VERSION"
  else
    warn "$README_FILE not found, skipping Flutter version update."
  fi
}

# ============================================================================
# Get Fastlane Bundler Requirements
# ============================================================================

function get_fastlane_bundler_requirements {
  progress "Checking Fastlane bundler requirements..."
  
  local fastlane_version=""
  local fastlane_gemfile=""
  local bundler_constraint=""
  
  # Check iOS Gemfile first, then Android
  for PLATFORM in ios android; do
    if [[ "$PLATFORM" == "ios" ]]; then
      fastlane_gemfile="${IOS_DIR}/Gemfile"
    else
      fastlane_gemfile="${ANDROID_DIR}/Gemfile"
    fi
    
    if [[ -f "$fastlane_gemfile" ]]; then
      fastlane_version=$(grep 'gem.*fastlane' "$fastlane_gemfile" | sed -n "s/.*['\"]fastlane['\"][[:space:]]*,[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" | head -n1)
      if [[ -n "$fastlane_version" ]]; then
        break
      fi
    fi
  done
  
  if [[ -z "$fastlane_version" ]]; then
    warn "Could not determine Fastlane version from Gemfiles, using latest bundler."
    return 1
  fi
  
  info "Found Fastlane version: $fastlane_version"
  
  # Get bundler requirements from Fastlane gem specification
  # The output is in YAML format, we need to extract the bundler dependency section
  local gem_spec_output
  gem_spec_output=$(gem specification fastlane -v "$fastlane_version" -r 2>/dev/null)
  
  if [[ -z "$gem_spec_output" ]]; then
    warn "Could not fetch Fastlane gem specification, using latest bundler."
    return 1
  fi
  
  # Extract bundler dependency section
  local bundler_section
  bundler_section=$(echo "$gem_spec_output" | sed -n '/name: bundler/,/^[[:space:]]*- !ruby\/object:Gem::Dependency/p' | head -15)
  
  if [[ -z "$bundler_section" ]]; then
    warn "Could not find bundler dependency in Fastlane gem specification, using latest bundler."
    return 1
  fi
  
  # Extract min and max versions from the requirements section
  # Format: version appears after ">=" and "<" operators
  local min_version max_version
  # Get version after ">=" operator (first version in requirements)
  min_version=$(echo "$bundler_section" | grep -A 3 '">="' | grep "version:" | head -n1 | sed -n 's/.*version:[[:space:]]*\([0-9.]*\).*/\1/p')
  # Get version after "<" operator (second version in requirements)
  max_version=$(echo "$bundler_section" | grep -A 3 '"<"' | grep "version:" | head -n1 | sed -n 's/.*version:[[:space:]]*\([0-9.]*\).*/\1/p')
  
  if [[ -z "$min_version" ]] && [[ -z "$max_version" ]]; then
    warn "Could not parse bundler version requirements, using latest bundler."
    return 1
  fi
  
  # Format as constraint string (e.g., ">= 1.12.0, < 3.0.0")
  local constraint_parts=()
  if [[ -n "$min_version" ]]; then
    constraint_parts+=(">= $min_version")
  fi
  if [[ -n "$max_version" ]]; then
    constraint_parts+=("< $max_version")
  fi
  
  # Join with comma and space
  if [[ ${#constraint_parts[@]} -eq 2 ]]; then
    bundler_constraint="${constraint_parts[0]}, ${constraint_parts[1]}"
  elif [[ ${#constraint_parts[@]} -eq 1 ]]; then
    bundler_constraint="${constraint_parts[0]}"
  else
    bundler_constraint=""
  fi
  
  info "Fastlane requires bundler: $bundler_constraint"
  echo "$bundler_constraint"
  return 0
}

# ============================================================================
# Get Compatible Bundler Version
# ============================================================================

function get_compatible_bundler_version {
  progress "Determining compatible bundler version..."
  
  local fastlane_requirements
  fastlane_requirements=$(get_fastlane_bundler_requirements)
  
  if [[ -z "$fastlane_requirements" ]]; then
    # If we can't determine requirements, try to get latest bundler
    LATEST_BUNDLER_VERSION=$(gem search "^bundler$" --remote --all | grep "^bundler " | sed -E 's/^bundler \(([^,]+).*/\1/')
    COMPATIBLE_BUNDLER_VERSION="$LATEST_BUNDLER_VERSION"
    return 0
  fi
  
  # Parse constraint (e.g., ">= 1.12.0, < 3.0.0" or ">= 1.12.0,< 3.0.0")
  local min_version max_version
  # Normalize: ensure comma is followed by exactly one space for consistent parsing
  local normalized_requirements
  normalized_requirements="${fastlane_requirements//,/, }"     # Add space after comma if missing
  normalized_requirements="${normalized_requirements//  / }"   # Collapse multiple spaces to single space
  min_version=$(echo "$normalized_requirements" | sed -n 's/.*>=[[:space:]]*\([0-9.]*\).*/\1/p')
  max_version=$(echo "$normalized_requirements" | sed -n 's/.*<[[:space:]]*\([0-9.]*\).*/\1/p')
  
  # Debug: show parsed versions
  if [[ -n "$min_version" ]]; then
    info "Parsed minimum bundler version: $min_version"
  fi
  if [[ -n "$max_version" ]]; then
    info "Parsed maximum bundler version: $max_version"
  fi
  
  if [[ -n "$min_version" ]]; then
    info "Fastlane minimum bundler requirement: >= $min_version"
  fi
  
  # Get latest bundler version
  LATEST_BUNDLER_VERSION=$(gem search "^bundler$" --remote --all | grep "^bundler " | sed -E 's/^bundler \(([^,]+).*/\1/')
  
  if [[ -z "$LATEST_BUNDLER_VERSION" ]]; then
    error_exit "Could not fetch latest bundler version."
  fi
  
  # Extract major version from latest bundler
  local latest_major
  latest_major=$(echo "$LATEST_BUNDLER_VERSION" | cut -d. -f1)
  
  # Check if latest bundler satisfies max constraint
  if [[ -n "$max_version" ]]; then
    local max_major
    max_major=$(echo "$max_version" | cut -d. -f1)
    
    if [[ "$latest_major" -ge "$max_major" ]]; then
      # Latest bundler is too new, find the latest compatible version
      info "Latest bundler $LATEST_BUNDLER_VERSION exceeds Fastlane constraint (< $max_version)"
      progress "Finding latest compatible bundler version..."
      
      # Get all bundler versions from RubyGems API and filter for compatible ones
      progress "Fetching all bundler versions from RubyGems..."
      local compatible_version
      
      # Use RubyGems API to get all versions as JSON, then extract version numbers
      local api_response
      api_response=$(curl -s "https://rubygems.org/api/v1/versions/bundler.json" 2>/dev/null)
      
      local all_versions=()
      if [[ -z "$api_response" ]]; then
        warn "Could not fetch bundler versions from RubyGems API, trying gem search..."
        # Fallback to gem search
        while IFS= read -r line; do all_versions+=("$line"); done < <(gem search "^bundler$" --remote --all 2>/dev/null | grep "^bundler " | sed -E 's/^bundler \(([^)]+)\).*/\1/' | tr ',' '\n' | tr -d ' ')
      else
        # Extract version numbers from JSON response
        # Get more versions to ensure we find the latest compatible one
        while IFS= read -r line; do all_versions+=("$line"); done < <(echo "$api_response" | grep -o '"number":"[^"]*"' | sed 's/"number":"\([^"]*\)"/\1/' | head -100)
      fi

      if [[ ${#all_versions[@]} -eq 0 ]]; then
        warn "Could not fetch bundler versions."
      else
        local compatible_versions=()

        for ver in "${all_versions[@]}"; do
          # Skip pre-release versions (alpha, beta, rc, etc.)
          if [[ "$ver" =~ (alpha|beta|rc|pre|dev) ]]; then
            continue
          fi

          local ver_major
          ver_major=$(echo "$ver" | cut -d. -f1)

          # Check if version satisfies max constraint (major < max_major)
          if [[ "$ver_major" -lt "$max_major" ]]; then
            # Check min constraint using awk for portable version comparison
            local satisfies_min=true
            if [[ -n "$min_version" ]]; then
              # ver >= min_version iff awk version comparator returns 1
              local cmp_result
              cmp_result=$(printf '%s\n%s\n' "$min_version" "$ver" | awk -F. '
                NR==1 { for(i=1;i<=NF;i++) a[i]=$i; na=NF }
                NR==2 {
                  n = (NF > na) ? NF : na
                  for(i=1;i<=n;i++) {
                    ai = (i<=na) ? a[i]+0 : 0
                    bi = (i<=NF) ? $i+0 : 0
                    if (bi > ai) { print "ge"; exit }
                    if (bi < ai) { print "lt"; exit }
                  }
                  print "ge"
                }
              ')
              if [[ "$cmp_result" == "lt" ]]; then
                satisfies_min=false
              fi
            fi

            if [[ "$satisfies_min" == true ]]; then
              compatible_versions+=("$ver")
            fi
          fi
        done

        if [[ ${#compatible_versions[@]} -gt 0 ]]; then
          # Sort versions portably using awk and get the latest
          compatible_version=$(printf '%s\n' "${compatible_versions[@]}" | awk -F. '
            {
              for(i=1;i<=NF;i++) a[i]=$i
              na=NF
              line=$0
              if (NR==1) { best=line; split(line,b,"."); nb=NF }
              else {
                nb2=NF
                n = (nb2 > nb) ? nb2 : nb
                for(i=1;i<=n;i++) {
                  ci = (i<=nb2) ? $i+0 : 0
                  bi = (i<=nb) ? b[i]+0 : 0
                  if (ci > bi) { best=line; split(line,b,"."); nb=nb2; break }
                  if (ci < bi) break
                }
              }
            }
            END { print best }
          ')
        fi
      fi
      
      if [[ -n "$compatible_version" ]]; then
        COMPATIBLE_BUNDLER_VERSION="$compatible_version"
        info "Using compatible bundler version: $COMPATIBLE_BUNDLER_VERSION (instead of latest $LATEST_BUNDLER_VERSION)"
      else
        warn "Could not find compatible bundler version, using latest: $LATEST_BUNDLER_VERSION"
        COMPATIBLE_BUNDLER_VERSION="$LATEST_BUNDLER_VERSION"
      fi
    else
      COMPATIBLE_BUNDLER_VERSION="$LATEST_BUNDLER_VERSION"
      info "Latest bundler $LATEST_BUNDLER_VERSION is compatible with Fastlane"
    fi
  else
    COMPATIBLE_BUNDLER_VERSION="$LATEST_BUNDLER_VERSION"
    info "No max constraint found, using latest bundler: $LATEST_BUNDLER_VERSION"
  fi
}

# ============================================================================
# Setup Ruby Environment
# ============================================================================

function setup_ruby_environment {
  progress "Setting up Ruby environment..."
  
  # Ensure rbenv is installed and Ruby is installed via rbenv before proceeding
  if ! command -v rbenv >/dev/null 2>&1; then
    info "rbenv not found. Installing rbenv via Homebrew..."
    brew install rbenv
    export PATH="$HOME/.rbenv/bin:$PATH"
  else
    export PATH="$HOME/.rbenv/bin:$PATH"
  fi
  
  # Initialize rbenv
  if ! eval "$(rbenv init - sh)"; then
    error "Failed to initialize rbenv."
    exit 1
  fi

  # Check if the specified Ruby version is installed via rbenv, if not, install it
  if ! rbenv versions --bare | grep -q "^${RUBY_VERSION}$"; then
    info "Ruby ${RUBY_VERSION} not found in rbenv. Installing Ruby ${RUBY_VERSION}..."
    rbenv install "${RUBY_VERSION}"
  fi

  # Set the specified Ruby version as global and shell version
  rbenv shell "${RUBY_VERSION}"
  RBENV_ROOT=$(rbenv root)
  export PATH="$RBENV_ROOT/shims:$PATH"

  local CURRENT_RUBY_VERSION
  CURRENT_RUBY_VERSION=$(ruby -e 'print RUBY_VERSION')
  success "Using Ruby $CURRENT_RUBY_VERSION (via rbenv)"

  # Configure gem to use a local cache directory in the current workspace
  local GEM_CACHE_DIR
  GEM_CACHE_DIR="$(pwd)/${GEM_CACHE_DIR_NAME}"
  mkdir -p "$GEM_CACHE_DIR"
  export GEM_HOME="$GEM_CACHE_DIR"
  export GEM_PATH="$GEM_CACHE_DIR"
  export GEM_SPEC_CACHE="$GEM_CACHE_DIR/specs"
  export PATH="$GEM_CACHE_DIR/bin:$PATH"

  # Get compatible bundler version (checks Fastlane requirements)
  get_compatible_bundler_version
  
  if [[ -z "$COMPATIBLE_BUNDLER_VERSION" ]]; then
    error_exit "Could not determine compatible bundler version."
  fi

  info "Installing bundler version $COMPATIBLE_BUNDLER_VERSION..."

  # Check the required Ruby version for this bundler version
  local REQUIRED_RUBY_VERSION
  REQUIRED_RUBY_VERSION=$(gem specification bundler -v "$COMPATIBLE_BUNDLER_VERSION" -r 2>/dev/null | awk '
    found_req && $1 == "version:" { print $2; exit }
    $1 == "requirements:" { found_req=1 }
  ')

  if [[ -n "$REQUIRED_RUBY_VERSION" ]]; then
    # Compare Ruby versions (only checks minimum required) using awk for portability
    local ver_lower
    ver_lower=$(printf '%s\n%s\n' "$REQUIRED_RUBY_VERSION" "$CURRENT_RUBY_VERSION" | awk -F. '
      NR==1 { for(i=1;i<=NF;i++) a[i]=$i }
      NR==2 {
        for(i=1;i<=NF;i++) {
          if ((a[i]+0) < ($i+0)) { print ARGV[1]; exit }
          if ((a[i]+0) > ($i+0)) { print ARGV[2]; exit }
        }
        print ARGV[1]
      }
    ' "$REQUIRED_RUBY_VERSION" "$CURRENT_RUBY_VERSION")
    if [[ "$ver_lower" != "$REQUIRED_RUBY_VERSION" ]]; then
      warn "Bundler $COMPATIBLE_BUNDLER_VERSION requires Ruby >= $REQUIRED_RUBY_VERSION, but current Ruby is $CURRENT_RUBY_VERSION."
      info "Attempting to install Ruby $REQUIRED_RUBY_VERSION using rbenv..."
      rbenv install -s "$REQUIRED_RUBY_VERSION"
      rbenv shell "$REQUIRED_RUBY_VERSION"
      RBENV_ROOT=$(rbenv root)
      export PATH="$RBENV_ROOT/shims:$PATH"
      CURRENT_RUBY_VERSION=$(ruby -e 'print RUBY_VERSION')
      success "Switched to Ruby $CURRENT_RUBY_VERSION"
    fi
  fi

  gem install bundler -v "$COMPATIBLE_BUNDLER_VERSION"
  
  # Store the compatible version as LATEST_BUNDLER_VERSION for later use
  LATEST_BUNDLER_VERSION="$COMPATIBLE_BUNDLER_VERSION"
  
  success "Ruby environment setup complete."
}

# ============================================================================
# Backup and Restore Functions
# ============================================================================

function backup_gemfiles {
  progress "Creating backup of Gemfiles and Pluginfiles..."
  
  rm -rf "$BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  
  for PLATFORM in ios android; do
    if [[ "$PLATFORM" == "ios" ]]; then
      PLATFORM_DIR="$IOS_DIR"
    else
      PLATFORM_DIR="$ANDROID_DIR"
    fi
    
    # Backup Gemfile
    if [[ -f "${PLATFORM_DIR}/Gemfile" ]]; then
      cp "${PLATFORM_DIR}/Gemfile" "${BACKUP_DIR}/${PLATFORM}_Gemfile.bak"
      info "Backed up ${PLATFORM}/Gemfile"
    fi
    
    # Backup Pluginfile
    if [[ -f "${PLATFORM_DIR}/fastlane/Pluginfile" ]]; then
      mkdir -p "${BACKUP_DIR}/${PLATFORM}_fastlane"
      cp "${PLATFORM_DIR}/fastlane/Pluginfile" "${BACKUP_DIR}/${PLATFORM}_fastlane/Pluginfile.bak"
      info "Backed up ${PLATFORM}/fastlane/Pluginfile"
    fi
  done
  
  success "Backup complete."
}

function restore_gemfiles {
  progress "Restoring Gemfiles and Pluginfiles from backup..."
  
  if [[ ! -d "$BACKUP_DIR" ]]; then
    warn "No backup directory found, skipping restore."
    return 1
  fi
  
  for PLATFORM in ios android; do
    if [[ "$PLATFORM" == "ios" ]]; then
      PLATFORM_DIR="$IOS_DIR"
    else
      PLATFORM_DIR="$ANDROID_DIR"
    fi
    
    # Restore Gemfile
    if [[ -f "${BACKUP_DIR}/${PLATFORM}_Gemfile.bak" ]]; then
      cp "${BACKUP_DIR}/${PLATFORM}_Gemfile.bak" "${PLATFORM_DIR}/Gemfile"
      info "Restored ${PLATFORM}/Gemfile"
    fi
    
    # Restore Pluginfile
    if [[ -f "${BACKUP_DIR}/${PLATFORM}_fastlane/Pluginfile.bak" ]]; then
      cp "${BACKUP_DIR}/${PLATFORM}_fastlane/Pluginfile.bak" "${PLATFORM_DIR}/fastlane/Pluginfile"
      info "Restored ${PLATFORM}/fastlane/Pluginfile"
    fi
  done
  
  success "Restore complete."
}

function cleanup_backup {
  if [[ -d "$BACKUP_DIR" ]]; then
    rm -rf "$BACKUP_DIR"
    info "Cleaned up backup directory."
  fi
}

# ============================================================================
# Update Gemfiles and Pluginfiles
# ============================================================================

# Helper to update version in Gemfile and Pluginfile
function update_version_in_file {
  local file="$1"
  local name="$2"
  local latest_version

  # Get the newest version number from RubyGems
  latest_version=$(gem search "^$name$" --remote --all | grep "^$name " | head -n1 | awk -F'[(),]' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
  if [[ -z "$latest_version" ]]; then
    warn "Could not fetch newest version for $name, skipping."
    return 1
  fi

  # Update the version in the file (Gemfile or Pluginfile) using the version number
  if grep -q "$name" "$file"; then
    info "Updating $name to $latest_version in $file"
    # Replace any fixed version (e.g. 'fastlane', '~> 2.220.0' or 'fastlane', '2.220.0')
    # Only update lines matching: gem "<plugin-name>", "<version>"
    if ! sed -i.bak -E "/^[[:space:]]*gem[[:space:]]+['\"]${name}['\"][[:space:]]*,[[:space:]]*['\"][^'\"]+['\"]/s/(^[[:space:]]*gem[[:space:]]+['\"]${name}['\"][[:space:]]*,[[:space:]]*)['\"][^'\"]+['\"]/\\1\"$latest_version\"/" "$file"; then
      rm -f "$file.bak"
      return 1
    fi
    rm -f "$file.bak"
  fi
  
  return 0
}

function update_pluginfiles {
  progress "Updating Pluginfiles..."
  
  local update_failed=0
  
  # Upgrade fastlane Pluginfile for both android and ios if present
  for PLATFORM in android ios; do
    if [[ "$PLATFORM" == "ios" ]]; then
      PLATFORM_DIR="$IOS_DIR"
    else
      PLATFORM_DIR="$ANDROID_DIR"
    fi
    local FASTLANE_DIR="${PLATFORM_DIR}/fastlane"
    if [[ -d "$FASTLANE_DIR" ]]; then
      info "Checking fastlane plugins in $FASTLANE_DIR..."

      local PLUGINFILE="$FASTLANE_DIR/Pluginfile"

      if [[ -f "$PLUGINFILE" ]]; then
        progress "Updating Pluginfile versions..."
        # Extract all plugin names
        # Pluginfile plugins are declared as: gem "<plugin-name>", "<version>"
        # Store plugins in array to avoid subshell issues with pipeline
        local plugins=()
        while IFS= read -r line; do plugins+=("$line"); done < <(awk '
          $1 == "gem" && match($0, /gem ["'\'']([^"'\'']+)["'\''],[[:space:]]*["'\''][^"'\'']+["'\'']/) {
            split($0, arr, /["'\'']/)
            print arr[2]
          }
        ' "$PLUGINFILE")
        
        for plugin in "${plugins[@]}"; do
          if ! update_version_in_file "$PLUGINFILE" "$plugin"; then
            update_failed=1
          fi
        done
      fi
    fi
  done
  
  if [[ $update_failed -eq 1 ]]; then
    return 1
  fi
  
  success "Pluginfiles updated."
  return 0
}

function update_gemfiles {
  progress "Updating Gemfiles..."
  
  local update_failed=0
  
  # Separately update Gemfile for both ios and android if present
  for PLATFORM in ios android; do
    if [[ "$PLATFORM" == "ios" ]]; then
      PLATFORM_DIR="$IOS_DIR"
    else
      PLATFORM_DIR="$ANDROID_DIR"
    fi
    local GEMFILE="${PLATFORM_DIR}/Gemfile"
    if [[ -f "$GEMFILE" ]]; then
      info "Updating Gemfile versions in $GEMFILE..."
      # Store gems in array to avoid subshell issues with pipeline
      local gems=()
      while IFS= read -r line; do gems+=("$line"); done < <(awk '
        $1 == "gem" && match($0, /gem ["'\'']([^"'\'']+)["'\''],[[:space:]]*["'\''][^"'\'']+["'\'']/) {
          split($0, arr, /["'\'']/)
          print arr[2]
        }
      ' "$GEMFILE")
      
      for gem in "${gems[@]}"; do
        if ! update_version_in_file "$GEMFILE" "$gem"; then
          update_failed=1
        fi
      done
    fi
  done
  
  if [[ $update_failed -eq 1 ]]; then
    return 1
  fi
  
  success "Gemfiles updated."
  return 0
}

# ============================================================================
# Run Bundle Updates
# ============================================================================

function run_bundle_updates {
  progress "Running bundle updates..."
  
  # After all Gemfiles are updated, run bundle update in each platform directory if Gemfile exists
  for PLATFORM in ios android; do
    if [[ "$PLATFORM" == "ios" ]]; then
      PLATFORM_DIR="$IOS_DIR"
    else
      PLATFORM_DIR="$ANDROID_DIR"
    fi
    local GEMFILE="${PLATFORM_DIR}/Gemfile"
    if [[ -f "$GEMFILE" ]]; then
      info "Running bundle update in $PLATFORM..."
      if [[ "$DRY_RUN" -eq 1 ]]; then
        info "DRY RUN: would run bundle _${LATEST_BUNDLER_VERSION}_ update in $PLATFORM_DIR"
      elif ! (cd "$PLATFORM_DIR" && bundle _"${LATEST_BUNDLER_VERSION}"_ update); then
        error "Bundle update failed for $PLATFORM"
        return 1
      fi
    fi
  done
  
  success "Bundle updates complete."
  return 0
}

# ============================================================================
# Update GitLab CI Ruby and Bundler Versions
# ============================================================================

function update_gitlab_ci_ruby_bundler_versions {
  progress "Updating GitLab CI Ruby and Bundler versions..."
  
  local GITLAB_CI_YML="./.gitlab/ci_templates/build.gitlab-ci.yml"

  if [[ -f "$GITLAB_CI_YML" ]]; then
    info "Updating RUBY_VERSION and BUNDLER_VERSION in $GITLAB_CI_YML..."
    # Update RUBY_VERSION and BUNDLER_VERSION in $GITLAB_CI_YML using single quotes
    local TMP_CI_YML="${GITLAB_CI_YML}.tmp"
    local RUBY_VERSION_VALUE="${RUBY_VERSION:-$(ruby -e 'print RUBY_VERSION')}"
    local BUNDLER_VERSION_VALUE="${LATEST_BUNDLER_VERSION}"

    awk -v ruby_version="$RUBY_VERSION_VALUE" -v bundler_version="$BUNDLER_VERSION_VALUE" '
      BEGIN { in_variables=0 }
      /^[[:space:]]*variables:/ { in_variables=1; print; next }
      in_variables && /^[[:space:]]*RUBY_VERSION:/ {
        print $0
        getline
        while ($0 ~ /^[[:space:]]*value:/) getline
        print "    value: '\''" ruby_version "'\''"
        print "    expand: false"
        next
      }
      in_variables && /^[[:space:]]*BUNDLER_VERSION:/ {
        print $0
        getline
        while ($0 ~ /^[[:space:]]*value:/) getline
        print "    value: '\''" bundler_version "'\''"
        print "    expand: false"
        next
      }
      in_variables && /^[^[:space:]]/ { in_variables=0 }
      { print }
    ' "$GITLAB_CI_YML" > "$TMP_CI_YML" && mv "$TMP_CI_YML" "$GITLAB_CI_YML"
    success "GitLab CI Ruby and Bundler versions updated."
  else
    warn "$GITLAB_CI_YML not found, skipping Ruby/Bundler version update in CI config."
  fi
}

# ============================================================================
# Run Pod Install
# ============================================================================

function run_pod_install {
  progress "Running pod install..."
  
  # Remove Podfile.lock before pod install
  if [[ -f "$IOS_PODFILE_LOCK" ]]; then
    info "Removing $IOS_PODFILE_LOCK before pod install..."
    rm "$IOS_PODFILE_LOCK"
  fi

  # Run pod install with repo update in ios directory
  info "Running pod install with repo update in ios directory..."
  pod repo update && pod install --project-directory="$IOS_DIR"
  
  success "Pod install complete."
}

# ============================================================================
# Update Gradle Components
# ============================================================================

# Helper to extract version from Maven metadata
function get_latest_maven_version {
  local group_id="$1"
  local artifact_id="$2"
  local use_google_maven="$3"  # Optional: use Google Maven for Android artifacts
  local maven_url metadata_url
  
  # Use Google Maven for Android/Firebase artifacts, Maven Central for others
  if [[ "${use_google_maven}" == "true" ]]; then
    maven_url="https://dl.google.com/dl/android/maven2"
  else
    maven_url="https://repo1.maven.org/maven2"
  fi
  
  # Convert group_id dots to slashes
  local group_path="${group_id//./\/}"
  metadata_url="${maven_url}/${group_path}/${artifact_id}/maven-metadata.xml"
  
  local latest_version
  local metadata_content
  
  # Fetch metadata once
  metadata_content=$(curl -sf "${metadata_url}")
  
  if [[ -z "${metadata_content}" ]]; then
    warn "Could not fetch metadata from ${metadata_url}"
    return 0
  fi
  
  # ALWAYS get the latest stable version by filtering the versions list
  # This ensures we never get alpha, beta, rc, or other pre-release versions
  latest_version=$(echo "${metadata_content}" | sed -n 's/.*<version>\([^<]*\)<\/version>.*/\1/p' | grep -v -iE '(alpha|beta|rc|dev|snapshot|milestone|preview)' | tail -n1)
  
  if [[ -z "${latest_version}" ]]; then
    # If no stable version found, try release tag (should be stable)
    latest_version=$(echo "${metadata_content}" | sed -n 's/.*<release>\([^<]*\)<\/release>.*/\1/p' | head -n1)
    # Double-check it's not a pre-release
    if echo "${latest_version}" | grep -qiE '(alpha|beta|rc|dev|snapshot|milestone|preview)'; then
      warn "Release tag contains pre-release version: ${latest_version}"
      latest_version=""
    fi
  fi
  
  echo "${latest_version}"
}

# Helper to get AGP-compatible Gradle version
function get_compatible_gradle_version {
  local agp_version="$1"
  local agp_major
  local agp_minor
  
  # Extract major.minor from AGP version
  agp_major=$(echo "${agp_version}" | cut -d. -f1)
  agp_minor=$(echo "${agp_version}" | cut -d. -f2)
  
  # AGP to Gradle compatibility mapping (based on official compatibility)
  # https://developer.android.com/build/releases/gradle-plugin#updating-gradle
  case "${agp_major}.${agp_minor}" in
    8.13|8.14|8.15)
      echo "8.14.3"
      ;;
    8.10|8.11|8.12)
      echo "8.10.2"
      ;;
    8.7|8.8|8.9)
      echo "8.9"
      ;;
    8.4|8.5|8.6)
      echo "8.6"
      ;;
    8.3)
      echo "8.4"
      ;;
    8.2)
      echo "8.2"
      ;;
    8.1)
      echo "8.0"
      ;;
    8.0)
      echo "8.0"
      ;;
    *)
      # Default to latest stable
      echo "8.14.3"
      ;;
  esac
}

function update_gradle_wrapper {
  progress "Updating Gradle wrapper..."
  
  local gradle_wrapper_props="${ANDROID_DIR}/gradle/wrapper/gradle-wrapper.properties"
  
  if [[ ! -f "${gradle_wrapper_props}" ]]; then
    warn "Gradle wrapper properties not found at ${gradle_wrapper_props}"
    return 0
  fi
  
  # Get current AGP version from settings.gradle.kts to ensure compatibility
  local current_agp_version
  current_agp_version=$(grep 'id("com\.android\.application")' "${ANDROID_DIR}/settings.gradle.kts" | sed -n 's/.*version[[:space:]]*"\([0-9.]*\)".*/\1/p' | head -n1)
  
  if [[ -z "${current_agp_version}" ]]; then
    warn "Could not determine AGP version, skipping Gradle wrapper update"
    return 0
  fi
  
  info "Current AGP version: ${current_agp_version}"
  
  # Get compatible Gradle version
  local recommended_gradle
  recommended_gradle=$(get_compatible_gradle_version "${current_agp_version}")
  
  # Get current Gradle version
  local current_gradle
  current_gradle=$(grep 'distributionUrl' "${gradle_wrapper_props}" | sed -n 's/.*gradle-\([0-9.]*\)-.*/\1/p')
  
  info "Current Gradle version: ${current_gradle}"
  info "Recommended Gradle version for AGP ${current_agp_version}: ${recommended_gradle}"
  
  if [[ "${current_gradle}" != "${recommended_gradle}" ]]; then
    progress "Updating Gradle wrapper to ${recommended_gradle}..."
    if [[ "$DRY_RUN" -eq 1 ]]; then
      info "DRY RUN: would update Gradle wrapper from ${current_gradle} to ${recommended_gradle}"
    else
      sed -i.bak "s|gradle-${current_gradle}-|gradle-${recommended_gradle}-|g" "${gradle_wrapper_props}"
      rm -f "${gradle_wrapper_props}.bak"
      success "Gradle wrapper updated to ${recommended_gradle}"
    fi
  else
    info "Gradle wrapper is already at recommended version"
  fi
}

function update_gradle_plugins {
  progress "Updating Gradle plugins in settings.gradle.kts..."
  
  local settings_gradle="${ANDROID_DIR}/settings.gradle.kts"
  
  if [[ ! -f "${settings_gradle}" ]]; then
    warn "settings.gradle.kts not found at ${settings_gradle}"
    return 0
  fi
  
  # Update Android Gradle Plugin (AGP)
  info "Checking Android Gradle Plugin version..."
  local latest_agp
  latest_agp=$(get_latest_maven_version "com.android.tools.build" "gradle" "true")
  
  if [[ -n "${latest_agp}" ]]; then
    local current_agp
    current_agp=$(grep 'id("com\.android\.application")' "${settings_gradle}" | sed -n 's/.*version[[:space:]]*"\([0-9.]*\)".*/\1/p' | head -n1)
    
    if [[ -n "${current_agp}" && "${current_agp}" != "${latest_agp}" ]]; then
      info "Updating AGP from ${current_agp} to ${latest_agp}..."
      sed -i.bak "s|id(\"com\.android\.application\") version \"[0-9.]*\"|id(\"com.android.application\") version \"${latest_agp}\"|g" "${settings_gradle}"
      success "AGP updated to ${latest_agp}"
    else
      info "AGP is up to date (${current_agp})"
    fi
  fi
  
  # Update Kotlin Plugin
  info "Checking Kotlin plugin version..."
  local latest_kotlin
  latest_kotlin=$(get_latest_maven_version "org.jetbrains.kotlin" "kotlin-gradle-plugin")
  
  if [[ -n "${latest_kotlin}" ]]; then
    local current_kotlin
    current_kotlin=$(grep 'id("org\.jetbrains\.kotlin\.android")' "${settings_gradle}" | sed -n 's/.*version[[:space:]]*"\([0-9.]*\)".*/\1/p' | head -n1)
    
    if [[ -n "${current_kotlin}" && "${current_kotlin}" != "${latest_kotlin}" ]]; then
      info "Updating Kotlin from ${current_kotlin} to ${latest_kotlin}..."
      sed -i.bak "s|id(\"org\.jetbrains\.kotlin\.android\") version \"[0-9.]*\"|id(\"org.jetbrains.kotlin.android\") version \"${latest_kotlin}\"|g" "${settings_gradle}"
      success "Kotlin plugin updated to ${latest_kotlin}"
    else
      info "Kotlin plugin is up to date (${current_kotlin})"
    fi
  fi
  
  # Update Google Services Plugin
  info "Checking Google Services plugin version..."
  local latest_gms
  latest_gms=$(get_latest_maven_version "com.google.gms" "google-services" "true")
  
  if [[ -n "${latest_gms}" ]]; then
    local current_gms
    current_gms=$(grep 'id("com\.google\.gms\.google-services")' "${settings_gradle}" | sed -n 's/.*version[[:space:]]*"\([0-9.]*\)".*/\1/p' | head -n1)
    
    if [[ -n "${current_gms}" && "${current_gms}" != "${latest_gms}" ]]; then
      info "Updating Google Services from ${current_gms} to ${latest_gms}..."
      sed -i.bak "s|id(\"com\.google\.gms\.google-services\") version \"[0-9.]*\"|id(\"com.google.gms.google-services\") version \"${latest_gms}\"|g" "${settings_gradle}"
      success "Google Services plugin updated to ${latest_gms}"
    else
      info "Google Services plugin is up to date (${current_gms})"
    fi
  fi
  
  # Update Firebase Performance Plugin
  info "Checking Firebase Performance plugin version..."
  local latest_perf
  latest_perf=$(get_latest_maven_version "com.google.firebase" "perf-plugin" "true")
  
  if [[ -n "${latest_perf}" ]]; then
    local current_perf
    current_perf=$(grep 'id("com\.google\.firebase\.firebase-perf")' "${settings_gradle}" | sed -n 's/.*version[[:space:]]*"\([0-9.]*\)".*/\1/p' | head -n1)
    
    if [[ -n "${current_perf}" && "${current_perf}" != "${latest_perf}" ]]; then
      info "Updating Firebase Performance from ${current_perf} to ${latest_perf}..."
      sed -i.bak "s|id(\"com\.google\.firebase\.firebase-perf\") version \"[0-9.]*\"|id(\"com.google.firebase.firebase-perf\") version \"${latest_perf}\"|g" "${settings_gradle}"
      success "Firebase Performance plugin updated to ${latest_perf}"
    else
      info "Firebase Performance plugin is up to date (${current_perf})"
    fi
  fi
  
  # Update Firebase Crashlytics Plugin
  info "Checking Firebase Crashlytics plugin version..."
  local latest_crashlytics
  latest_crashlytics=$(get_latest_maven_version "com.google.firebase" "firebase-crashlytics-gradle" "true")
  
  if [[ -n "${latest_crashlytics}" ]]; then
    local current_crashlytics
    current_crashlytics=$(grep 'id("com\.google\.firebase\.crashlytics")' "${settings_gradle}" | sed -n 's/.*version[[:space:]]*"\([0-9.]*\)".*/\1/p' | head -n1)
    
    if [[ -n "${current_crashlytics}" && "${current_crashlytics}" != "${latest_crashlytics}" ]]; then
      info "Updating Firebase Crashlytics from ${current_crashlytics} to ${latest_crashlytics}..."
      sed -i.bak "s|id(\"com\.google\.firebase\.crashlytics\") version \"[0-9.]*\"|id(\"com.google.firebase.crashlytics\") version \"${latest_crashlytics}\"|g" "${settings_gradle}"
      success "Firebase Crashlytics plugin updated to ${latest_crashlytics}"
    else
      info "Firebase Crashlytics plugin is up to date (${current_crashlytics})"
    fi
  fi
  
  # Clean up backup files
  rm -f "${settings_gradle}.bak"
  
  success "Gradle plugins check complete."
}

function update_gradle_dependencies {
  progress "Updating Gradle dependencies in build.gradle.kts..."
  
  local build_gradle="${ANDROID_DIR}/app/build.gradle.kts"
  
  if [[ ! -f "${build_gradle}" ]]; then
    warn "build.gradle.kts not found at ${build_gradle}"
    return 0
  fi
  
  # Update Firebase Analytics
  info "Checking Firebase Analytics version..."
  local latest_analytics
  latest_analytics=$(get_latest_maven_version "com.google.firebase" "firebase-analytics-ktx" "true")
  
  if [[ -n "${latest_analytics}" ]]; then
    local current_analytics
    current_analytics=$(grep 'com\.google\.firebase:firebase-analytics-ktx' "${build_gradle}" | sed -n 's/.*:\([0-9.]*\)".*/\1/p')
    
    if [[ -n "${current_analytics}" && "${current_analytics}" != "${latest_analytics}" ]]; then
      info "Updating Firebase Analytics from ${current_analytics} to ${latest_analytics}..."
      sed -i.bak "s|com\.google\.firebase:firebase-analytics-ktx:[0-9.]*|com.google.firebase:firebase-analytics-ktx:${latest_analytics}|g" "${build_gradle}"
      success "Firebase Analytics updated to ${latest_analytics}"
    else
      info "Firebase Analytics is up to date (${current_analytics})"
    fi
  fi
  
  # Update Desugar JDK Libs
  info "Checking Desugar JDK Libs version..."
  local latest_desugar
  latest_desugar=$(get_latest_maven_version "com.android.tools" "desugar_jdk_libs" "true")
  
  if [[ -n "${latest_desugar}" ]]; then
    local current_desugar
    current_desugar=$(grep 'com\.android\.tools:desugar_jdk_libs' "${build_gradle}" | sed -n 's/.*:\([0-9.]*\)".*/\1/p')
    
    if [[ -n "${current_desugar}" && "${current_desugar}" != "${latest_desugar}" ]]; then
      info "Updating Desugar JDK Libs from ${current_desugar} to ${latest_desugar}..."
      sed -i.bak "s|com\.android\.tools:desugar_jdk_libs:[0-9.]*|com.android.tools:desugar_jdk_libs:${latest_desugar}|g" "${build_gradle}"
      success "Desugar JDK Libs updated to ${latest_desugar}"
    else
      info "Desugar JDK Libs is up to date (${current_desugar})"
    fi
  fi
  
  # Update AndroidX Window
  info "Checking AndroidX Window version..."
  local latest_window
  latest_window=$(get_latest_maven_version "androidx.window" "window" "true")
  
  if [[ -n "${latest_window}" ]]; then
    local current_window
    current_window=$(grep 'androidx\.window:window:' "${build_gradle}" | sed -n 's/.*:\([0-9.]*\)".*/\1/p' | head -n1)
    
    if [[ -n "${current_window}" && "${current_window}" != "${latest_window}" ]]; then
      info "Updating AndroidX Window from ${current_window} to ${latest_window}..."
      sed -i.bak "s|androidx\.window:window:[0-9.]*|androidx.window:window:${latest_window}|g" "${build_gradle}"
      sed -i.bak "s|androidx\.window:window-java:[0-9.]*|androidx.window:window-java:${latest_window}|g" "${build_gradle}"
      success "AndroidX Window updated to ${latest_window}"
    else
      info "AndroidX Window is up to date (${current_window})"
    fi
  fi
  
  # Clean up backup files
  rm -f "${build_gradle}.bak"
  
  success "Gradle dependencies check complete."
}

function update_gradle_components {
  progress "Updating Android Gradle components..."
  
  # Update plugins in settings.gradle.kts first
  update_gradle_plugins
  
  # Update Gradle wrapper based on AGP version
  update_gradle_wrapper
  
  # Update dependencies in app/build.gradle.kts
  update_gradle_dependencies
  
  celebrate "Android Gradle components updated successfully!"
}

# ============================================================================
# Cleanup Gem Cache
# ============================================================================

function cleanup_gem_cache {
  progress "Cleaning up gem cache..."
  
  # Remove cached .gem files in the current workspace to ensure fresh installs
  if [[ -d "$GEM_CACHE_DIR_NAME" ]]; then
    info "Removing cached .gem files from $(pwd)/${GEM_CACHE_DIR_NAME}..."
    rm -rf "$GEM_CACHE_DIR_NAME"
  fi
  
  success "Gem cache cleanup complete."
}

# ============================================================================
# Update YQ Version
# ============================================================================

function update_yq_version {
  progress "Updating yq version in GitLab CI..."
  
  # Define variables for YQ_VERSION
  local YQ_VERSION_KEY="YQ_VERSION"

  # Check latest yq version from GitHub
  local LATEST_YQ_VERSION
  LATEST_YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')

  if [[ -z "$LATEST_YQ_VERSION" ]]; then
    warn "Could not fetch latest yq version from GitHub."
  else
    # Get current YQ_VERSION from .gitlab-ci.yml using yq
    local CURRENT_YQ_VERSION
    CURRENT_YQ_VERSION=$(yq '.variables.YQ_VERSION.value' "$MAIN_GITLAB_CI_YML" 2>/dev/null | tr -d "'\"")

    info "Current $YQ_VERSION_KEY in $MAIN_GITLAB_CI_YML: $CURRENT_YQ_VERSION"

    if [[ "$CURRENT_YQ_VERSION" != "$LATEST_YQ_VERSION" ]]; then
      progress "Updating $YQ_VERSION_KEY in $MAIN_GITLAB_CI_YML from $CURRENT_YQ_VERSION to $LATEST_YQ_VERSION..."
      local TMP_CI_YML="${MAIN_GITLAB_CI_YML}.tmp"
      awk -v yq_key="$YQ_VERSION_KEY" -v yq_version="$LATEST_YQ_VERSION" '
        BEGIN { in_variables=0 }
        /^[[:space:]]*variables:/ { in_variables=1; print; next }
        in_variables && (index($0, yq_key ":") > 0) {
          print $0
          getline
          while ($0 ~ /^[[:space:]]*value:/) getline
          print "    value: '\''" yq_version "'\''"
          print "    expand: false"
          next
        }
        in_variables && /^[^[:space:]]/ { in_variables=0 }
        { print }
      ' "$MAIN_GITLAB_CI_YML" > "$TMP_CI_YML" && mv "$TMP_CI_YML" "$MAIN_GITLAB_CI_YML"
      success "Successfully updated $YQ_VERSION_KEY in $MAIN_GITLAB_CI_YML to $LATEST_YQ_VERSION"
    else
      info "$YQ_VERSION_KEY in $MAIN_GITLAB_CI_YML is already up to date ($CURRENT_YQ_VERSION)."
    fi
  fi
}

# ============================================================================
# Update Dart Tool Versions in GitLab CI
# ============================================================================

# Helper to get latest stable version from pub.dev
function get_latest_pub_dev_version {
  local package_name="$1"
  local latest_version
  
  # Fetch package info from pub.dev API (with 10 second timeout)
  local api_response
  if ! api_response=$(curl -sf --max-time 10 "https://pub.dev/api/packages/${package_name}"); then
    warn "Could not fetch package info from pub.dev for ${package_name}"
    return 1
  fi
  
  if [[ -z "${api_response}" ]]; then
    warn "Empty response from pub.dev for ${package_name}"
    return 1
  fi
  
  # Extract latest version from "latest" field in JSON
  # This gives us the most recent version (stable or pre-release)
  if ! latest_version=$(grep -o '"latest"[[:space:]]*:[[:space:]]*{[^}]*"version"[[:space:]]*:[[:space:]]*"[^"]*"' <<< "${api_response}" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed 's/"version"[[:space:]]*:[[:space:]]*"//;s/"//'); then
    warn "Could not parse latest version from pub.dev response for ${package_name}"
    return 1
  fi
  
  if [[ -z "${latest_version}" ]]; then
    warn "Could not determine latest version for ${package_name}"
    return 1
  fi
  
  # Check if this is a pre-release version
  if grep -qiE '(dev|alpha|beta|rc|pre)' <<< "${latest_version}"; then
    # Try to find the latest stable version from versions list
    # Match version pattern: digit.digit.digit (with optional additional digits)
    local stable_version
    if stable_version=$(grep -oE '"[0-9]+\.[0-9]+\.[0-9]+[^"]*"' <<< "${api_response}" | tr -d '"' | grep -viE '(dev|alpha|beta|rc|pre)' | awk -F. '
      {
        line=$0
        if (NR==1) { best=line; split(line,b,"."); nb=NF }
        else {
          n = (NF > nb) ? NF : nb
          for(i=1;i<=n;i++) {
            ci = (i<=NF) ? $i+0 : 0
            bi = (i<=nb) ? b[i]+0 : 0
            if (ci > bi) { best=line; split(line,b,"."); nb=NF; break }
            if (ci < bi) break
          }
        }
      }
      END { print best }
    '); then
      if [[ -n "${stable_version}" ]]; then
        info "Using stable version ${stable_version} instead of pre-release ${latest_version} for ${package_name}"
        latest_version="${stable_version}"
      else
        warn "No stable version found for ${package_name}, using pre-release version: ${latest_version}"
      fi
    else
      warn "No stable version found for ${package_name}, using pre-release version: ${latest_version}"
    fi
  fi
  
  echo "${latest_version}"
  return 0
}

# Helper function for portable sed in-place editing (MacOS/Linux compatible)
function sed_inplace {
  local pattern="$1"
  local file="$2"
  
  # Use .bak extension for compatibility with both BSD (MacOS) and GNU (Linux) sed
  sed -i.bak "${pattern}" "${file}"
  rm -f "${file}.bak"
}

function update_gitlab_ci_dart_tool_versions {
  progress "Updating Dart tool versions in GitLab CI..."
  
  # Define CI template files
  local ENVIRONMENT_SETUP_CI="./.gitlab/ci_templates/environment_setup.gitlab-ci.yml"
  local ANALYZE_TEST_CI="./.gitlab/ci_templates/analyze_and_test.gitlab-ci.yml"
  
  # Define packages and their variables
  # Format: package_name:variable_name:file_path
  declare -a packages=(
    "fvm:FVM_VERSION:${ENVIRONMENT_SETUP_CI}"
    "test_cov_console:TEST_COV_CONSOLE_VERSION:${ENVIRONMENT_SETUP_CI}"
    "flutterfire_cli:FLUTTERFIRE_CLI_VERSION:${ENVIRONMENT_SETUP_CI}"
    "bloc_tools:BLOC_TOOL_VERSION:${ANALYZE_TEST_CI}"
    "junitreport:JUNIT_REPORT_VERSION:${ANALYZE_TEST_CI}"
  )
  
  # Update each package version
  for package_info in "${packages[@]}"; do
    IFS=':' read -r package_name variable_name file_path <<< "${package_info}"
    
    info "Checking ${package_name} version..."
    
    # Get latest version from pub.dev (SC2155 compliant)
    local latest_version
    if ! latest_version=$(get_latest_pub_dev_version "${package_name}"); then
      warn "Could not fetch latest version for ${package_name}, skipping."
      continue
    fi
    
    if [[ -z "${latest_version}" ]]; then
      warn "Empty version returned for ${package_name}, skipping."
      continue
    fi
    
    # Check if file exists
    if [[ ! -f "${file_path}" ]]; then
      warn "File not found: ${file_path}, skipping ${variable_name}."
      continue
    fi
    
    # Get current version from file (SC2155 compliant)
    local current_version
    if ! current_version=$(grep "^[[:space:]]*${variable_name}:" "${file_path}" | sed -n "s/^[[:space:]]*${variable_name}:[[:space:]]*['\"]\\([^'\"]*\\)['\"].*/\\1/p"); then
      warn "Could not read ${variable_name} from ${file_path}, skipping."
      continue
    fi
    
    if [[ -z "${current_version}" ]]; then
      warn "Could not find ${variable_name} in ${file_path}, skipping."
      continue
    fi
    
    info "Current ${package_name} version: ${current_version}"
    
    if [[ "${current_version}" != "${latest_version}" ]]; then
      progress "Updating ${variable_name} from ${current_version} to ${latest_version}..."
      
      # Update version in file (MacOS/Linux compatible)
      if sed_inplace "s/^\\([[:space:]]*${variable_name}:[[:space:]]*['\"]\\)[^'\"]*\\(['\"]\\)/\\1${latest_version}\\2/" "${file_path}"; then
        success "${package_name}: ${current_version} → ${latest_version}"
      else
        error "Failed to update ${package_name}"
      fi
    else
      info "${package_name} is already up to date (${current_version})"
    fi
  done
  
  success "Dart tool versions check complete."
}

# ============================================================================
# Main Execution
# ============================================================================

function parse_args {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --test)
        test_script
        exit 0
        ;;
      --dry-run|-n)
        DRY_RUN=1
        info "Dry-run mode enabled: destructive operations will be skipped."
        shift
        ;;
      --help|-h)
        echo "Usage: $(basename "${BASH_SOURCE[0]}") [--dry-run|-n] [--test] [--help|-h] [FLUTTER_VERSION]"
        echo ""
        echo "Options:"
        echo "  --dry-run, -n   Print what would be done without making changes."
        echo "  --test          Run bash -n and shellcheck syntax checks then exit."
        echo "  --help, -h      Show this help message and exit."
        echo ""
        echo "Arguments:"
        echo "  FLUTTER_VERSION  Target Flutter version (e.g. 3.22.0). Defaults to newest stable."
        exit 0
        ;;
      *)
        # Remaining argument is the Flutter version; pass through
        break
        ;;
    esac
  done
}

function main {
  parse_args "$@"
  # After parse_args has consumed flags, re-build positional args without flags
  # parse_args uses 'break' on first non-flag, so remaining $@ is unchanged here
  # We need to skip flags already consumed; use a separate passthrough
  local _remaining=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n) shift ;;
      --test|--help|-h) shift ;;
      *) _remaining+=("$1"); shift ;;
    esac
  done

  echo ""
  celebrate "Starting Flutter upgrade process..."
  echo "============================================================================"

  # Check required commands
  check_required_commands

  # Determine Flutter version
  determine_flutter_version "${_remaining[@]+"${_remaining[@]}"}"
  
  # Update pubspec files
  update_pubspec_files
  
  # Upgrade dependencies and remove carets
  upgrade_dependencies_and_remove_carets
  
  # Update GitLab CI Flutter version
  update_gitlab_ci_flutter_version
  
  # Update README Flutter version
  update_readme_flutter_version
  
  # Setup Ruby environment (with retry logic)
  local MAX_RETRIES=2
  local RETRY_COUNT=0
  
  while [[ $RETRY_COUNT -le $MAX_RETRIES ]]; do
    if [[ $RETRY_COUNT -gt 0 ]]; then
      warn "Retrying from setup_ruby_environment (attempt $RETRY_COUNT/$MAX_RETRIES)..."
      # Restore Gemfiles before retry
      restore_gemfiles
    fi
    
    # Setup Ruby environment
    if ! setup_ruby_environment; then
      error "Failed to setup Ruby environment"
      if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
        RETRY_COUNT=$((RETRY_COUNT + 1))
        continue
      else
        restore_gemfiles
        cleanup_backup
        error_exit "Failed to setup Ruby environment after $MAX_RETRIES attempts"
      fi
    fi
    
    # Backup Gemfiles before making changes
    backup_gemfiles
    
    # Update Pluginfiles
    if ! update_pluginfiles; then
      error "Failed to update Pluginfiles"
      restore_gemfiles
      if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
        RETRY_COUNT=$((RETRY_COUNT + 1))
        continue
      else
        cleanup_backup
        error_exit "Failed to update Pluginfiles after $MAX_RETRIES attempts"
      fi
    fi
    
    # Update Gemfiles
    if ! update_gemfiles; then
      error "Failed to update Gemfiles"
      restore_gemfiles
      if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
        RETRY_COUNT=$((RETRY_COUNT + 1))
        continue
      else
        cleanup_backup
        error_exit "Failed to update Gemfiles after $MAX_RETRIES attempts"
      fi
    fi
    
    # Run bundle updates
    if ! run_bundle_updates; then
      error "Bundle updates failed"
      restore_gemfiles
      warn "Bundler version $LATEST_BUNDLER_VERSION may be incompatible with Fastlane"
      if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
        RETRY_COUNT=$((RETRY_COUNT + 1))
        continue
      else
        cleanup_backup
        error_exit "Bundle updates failed after $MAX_RETRIES attempts. Please check Fastlane bundler requirements manually."
      fi
    fi
    
    # All succeeded, break out of retry loop
    break
  done
  
  # Cleanup backup on success
  cleanup_backup
  
  # Update GitLab CI Ruby and Bundler versions
  update_gitlab_ci_ruby_bundler_versions
  
  # Run pod install
  run_pod_install
  
  # Update Android Gradle components
  update_gradle_components
  
  # Cleanup gem cache
  cleanup_gem_cache
  
  # Update yq version
  update_yq_version
  
  # Update Dart tool versions in GitLab CI
  update_gitlab_ci_dart_tool_versions
  
  echo "============================================================================"
  celebrate "Flutter, Dart, and fastlane dependencies updated."
  celebrate "Upgrade process complete!"
  echo ""
}

# Run main function with all script arguments
main "$@"
