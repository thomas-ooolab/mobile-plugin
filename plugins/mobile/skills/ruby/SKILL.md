---
name: ruby
description: Defines Ruby coding standards for Fastlane automation in this repository, including lane/helper design, environment variable handling, shell command safety, and CI-compatible patterns. Use when editing Fastfiles, shared Fastlane Ruby files, or reviewing Ruby code used by mobile build/distribution pipelines.
---

# Ruby Coding Standards (Fastlane)

Use this skill when writing or reviewing Ruby code in:

- `ios/fastlane/Fastfile`
- `android/fastlane/Fastfile`
- shared Fastlane Ruby files in repo root (for example `GeneralFastFile`, `CommonFastfile`, `NotificationFastfile`)

## Goals

- Keep CI behavior deterministic and easy to debug.
- Keep lane APIs stable and helper logic reusable.
- Avoid shell/Ruby pitfalls that break non-interactive pipeline runs.

## File Responsibilities

- **Platform Fastfiles (`ios/fastlane/Fastfile`, `android/fastlane/Fastfile`)**
  - Keep minimal: import shared file, define small entry lanes (`build`, `upload`).
  - Do not duplicate business logic here.
- **Shared files (`GeneralFastFile`, `CommonFastfile`, `NotificationFastfile`)**
  - Put reusable logic in methods.
  - Prefer one source of truth for command options and env parsing.

## Naming and Structure

- Use `snake_case` for methods and locals.
- Method names should be action-oriented and explicit (`upload_store`, `get_version_command_options`).
- Keep methods focused:
  - one concern per method
  - avoid long branching blocks by extracting helpers
- Keep comments short and high-signal; explain intent, not syntax.

## Ruby Syntax Quick Reference

Use this section when writing or reviewing Ruby in Fastlane files.

### Variables and Constants

- Local variables: `build_number = ENV['BUILD_NUMBER']`
- Constants: `DEFAULT_TRACK = 'staging'`
- Constants in modules are typically ALL_CAPS.

### Method Definitions

```ruby
def upload_store(options = {})
  build_name = options[:build_name]
  # ...
end
```

- Use default hash args for optional parameters when needed.
- Return value is the last expression (no explicit `return` unless helpful).

### Conditionals

```ruby
if is_ios
  export_ipa
elsif is_android
  upload_debug_symbols
else
  UI.important('Unsupported platform')
end
```

- Prefer `if/elsif/else` for readability in shared CI logic.
- `case` is recommended for enum-like branching:

```ruby
case ENV['MANUAL_PIPELINE_OPTIONS']
when 'build' then ManualPipelineOptions::BUILD
when 'release' then ManualPipelineOptions::RELEASE
when 'patch' then ManualPipelineOptions::PATCH
else nil
end
```

### Arrays and Hashes

```ruby
command = [
  'shorebird', 'release', platform_name,
  *get_build_command_options,
  '--track', 'staging'
]

payload = {
  title: 'Build',
  short: true,
}
```

- Use symbols as hash keys for Ruby/Fastlane options (`title:`, `short:`).
- Use splat (`*`) to compose command option arrays.

### String Interpolation

```ruby
path = "#{ENV['SPLIT_DEBUG_INFO_PATH']}/learningos/#{flavor}"
message = "Successfully uploaded #{ENV['TARGET_APP_NAME']}"
```

- Prefer interpolation over string concatenation for readability.

### Nil / Empty Safety

```ruby
merge_request_id = ENV['MERGE_REQUEST_ID']
if !merge_request_id.nil? && !merge_request_id.strip.empty?
  # use merge_request_id
end
```

- Guard env variables before calling methods like `strip`.
- For concise conversions, `to_s.strip` is acceptable when semantics remain clear.

### Modules and Enums

```ruby
module ManualPipelineOptions
  BUILD = :build
  RELEASE = :release
  PATCH = :patch
end
```

- Use module constants as enum-like values for pipeline routing.

### Fastlane Calls

```ruby
sh(command: ['fvm', 'flutter', 'build', 'apk', '--profile'])

slack(
  slack_url: ENV['SLACK_URL'],
  success: true,
  attachment_properties: { title: 'Build' }
)
```

- Pass Fastlane action options as Ruby hashes.
- Keep hashes/arrays multiline when argument lists become long.

## Basic Ruby Syntax + Best Practices

This section is general Ruby guidance (not only Fastlane-specific).

### Data Types and Literals

```ruby
name = 'ooolab'         # String
count = 3               # Integer
price = 12.5            # Float
enabled = true          # Boolean
nothing = nil           # Nil
tags = ['ci', 'ruby']   # Array
meta = { team: 'mobile', retries: 2 } # Hash
```

Best practices:

- Use single quotes for static strings; double quotes when interpolation is needed.
- Use symbols for internal/static hash keys (`team:`) unless string keys are required.

### Assignment and Defaults

```ruby
api_env = ENV['API_ENV'] || 'production'
options ||= {}
```

Best practices:

- Use `||` for fallback values.
- Use `||=` only when setting a value once if currently `nil`/`false`.

### Comparisons and Boolean Logic

```ruby
if count > 0 && enabled
  puts 'ready'
end

if value.nil?
  # handle missing value
end
```

Best practices:

- Prefer predicate methods (`nil?`, `empty?`, `include?`) over manual checks.
- Keep boolean expressions short; extract helper methods if a condition is complex.

### Iteration (Prefer Enumerables)

```ruby
items.each do |item|
  puts item
end

names = users.map { |u| u[:name] }
active = users.select { |u| u[:active] }
```

Best practices:

- Prefer `each`, `map`, `select`, `find`, `any?`, `all?` over index-based loops.
- Avoid mutating collections unless required; prefer transformed copies.

### Safe Hash Access

```ruby
build_number = options[:build_number]
release_text = release[:releaseNotes]&.dig(:text)
```

Best practices:

- Use `dig` for nested hash access.
- Use safe navigation `&.` when a receiver may be `nil`.

### Classes and Modules

```ruby
module BuildMode
  INTERNAL = :internal
end

class Notifier
  def initialize(client)
    @client = client
  end
end
```

Best practices:

- Use modules for shared constants/helpers and namespace separation.
- Keep classes small and focused on one responsibility.

### Exception Handling

```ruby
begin
  do_work
rescue StandardError => e
  UI.important("Work failed: #{e}")
end
```

Best practices:

- Rescue `StandardError` (or narrower), not `Exception`.
- Rescue close to where you can recover.
- Log context in error messages.

### File Operations

```ruby
Dir.mkdir(out_dir) unless File.directory?(out_dir)
File.write(File.join(out_dir, 'result.txt'), content)
```

Best practices:

- Use `File.join` for path construction.
- Validate input/path assumptions before writing.

### Method and API Design

```ruby
def build_command(platform:, flavor:, version:)
  ['tool', platform, '--flavor', flavor, '--version', version]
end
```

Best practices:

- Prefer keyword arguments for methods with multiple parameters.
- Keep public methods small; extract private helpers for repeated logic.
- Name methods by intent (`upload_store`, `persist_link`) not implementation detail.

### Style Conventions

- 2-space indentation.
- `snake_case` for variables/methods, `CamelCase` for classes/modules.
- Keep line length readable; split long arrays/hashes onto multiple lines.
- Avoid deep nesting; return early or extract methods to reduce complexity.

## Lane and Helper Design

- Keep lane entrypoints thin; delegate to shared helper methods.
- Use explicit routing methods for behavior control (e.g., `build`, `upload`).
- Parse pipeline mode once in a helper (for example via enum-like module in `CommonFastfile`), then branch on that value.
- Avoid hardcoding platform-specific behavior in shared methods without `is_ios` / `is_android` checks.

## Environment Variable Rules

- Read env values via `ENV[...]` in one place when possible.
- Treat optional env vars as optional:
  - check presence before use (`nil` / empty guard)
  - only export/set optional vars when non-empty
- Keep env variable names consistent between CI YAML and Ruby code.
- Do not silently change meaning of existing env vars; update all call sites when renaming.

## Shell Command Safety (Fastlane `sh`)

- Build commands as arrays where possible:
  - `sh(command: ['tool', 'arg1', value])`
- Avoid string-concatenated shell commands unless necessary.
- Prefer explicit flags over implicit defaults when behavior matters.
- For CLI arguments that may be optional, gate them with Ruby conditionals.

## Fastlane-Specific Standards

- Use `UI.important` / `UI.message` for non-fatal diagnostic info.
- Rescue narrowly when needed and keep failure semantics clear.
- Keep Slack notification payload construction in dedicated methods.
- For iOS export options, keep provisioning profile mapping explicit and deterministic.

## Conditional Logic Guidelines

- Prefer positive, readable conditions over dense nested negations.
- When branching by pipeline mode:
  - `release` path should be explicit
  - `build` path should be explicit
  - `patch` path should be explicit
- If adding a new mode, update:
  - mode parser/helper
  - build routing
  - upload routing
  - related CI variables/rules

## CI Compatibility Checklist

Before finalizing Fastlane Ruby changes, verify:

- Method names called by platform lanes still exist.
- Shared helper signature changes are propagated to all callers.
- CI variables used by Ruby still match `.gitlab/ci_templates/*`.
- iOS and Android flows both remain valid.
- Optional vars do not break App Store flow when unset.

## Preferred Review Heuristics

When reviewing Ruby/Fastlane changes, prioritize:

1. Incorrect pipeline-mode routing (wrong upload/build path)
2. Env var mismatches between CI and Ruby
3. Unsafe command construction
4. Hidden behavior changes (changed defaults without documentation)
5. Cross-platform regressions (iOS works, Android breaks or vice versa)

## Example Patterns

### Good: explicit mode parsing

```ruby
module ManualPipelineOptions
  BUILD = :build
  RELEASE = :release
  PATCH = :patch
end

def get_manual_pipeline_options
  case ENV['MANUAL_PIPELINE_OPTIONS']
  when 'build' then ManualPipelineOptions::BUILD
  when 'release' then ManualPipelineOptions::RELEASE
  when 'patch' then ManualPipelineOptions::PATCH
  else nil
  end
end
```

### Good: optional env export

```ruby
if [[ -n "${SIGH_DEVELOPMENT:-}" ]]; then
  export SIGH_DEVELOPMENT=$SIGH_DEVELOPMENT
fi
```

### Good: shared option helpers

```ruby
def get_build_command_options
  [
    '--flavor', flavor,
    '--dart-define-from-file', "environment_configurations/.general.env"
  ]
end
```

## When This Skill Should Be Applied

Apply automatically when user asks to:

- change Fastlane lanes
- update Ruby helpers for CI/build/release
- refactor shared Fastlane files
- troubleshoot CI behavior rooted in Ruby/Fastlane logic
