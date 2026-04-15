---
name: ci-cd
description: Explains and updates this repository's GitLab CI/CD architecture, including stage flow, rule-based job triggering, child pipeline chaining, build/versioning/distribution behavior, and Fastlane integration. Use when modifying .gitlab-ci.yml, files in .gitlab/ci_templates/, or Fastlane files used by CI. When editing any GitLab CI file (`*.gitlab-ci.yml`), follow GitLab CI/CD YAML syntax (see skill section “GitLab CI YAML syntax”), not generic YAML alone. After editing GitLab CI YAML, run glab ci lint from the repository root.
---

# CI/CD Workflow (GitLab + Fastlane)

Use this skill when asked to explain, review, or modify CI/CD behavior in this repository.

## Scope

- Root pipeline orchestration: `.gitlab-ci.yml`
- CI templates: `.gitlab/ci_templates/*.gitlab-ci.yml`
- Mobile build/distribution child pipeline: `.gitlab/ci_templates/build.gitlab-ci.yml`
- Fastlane entry and shared logic:
  - `ios/fastlane/Fastfile`
  - `android/fastlane/Fastfile`
  - `GeneralFastFile`
  - `CommonFastfile`
  - `NotificationFastfile`

## High-level Pipeline Graph

Root stages in `.gitlab-ci.yml`:

1. `contribution`
2. `versioning`
3. `validation`
4. `asset`
5. `distribution`

There is also `.pre` stage from `environment_setup.gitlab-ci.yml` (`environment_setup` job).

Distribution jobs trigger a **child pipeline** by including `build.gitlab-ci.yml` with `strategy: depend`.

## How Jobs Are Triggered (Rules / if conditions)

When explaining behavior, always cite the concrete predicate.

### 1) Contribution checks (MR quality gate)

From `contribution.gitlab-ci.yml`, jobs run on MR pipelines:

- `branch_validation`
- `commit_validation`
- `merge_request_validation`

Rule:

- `if: $CI_MERGE_REQUEST_IID`

These validate:

- Branch naming (`feat|fix|ci|refactor|test|docs|chore/LOE-<id>` and release branch format)
- Commit message conventional commit regex
- MR title regex

### 2) Versioning jobs

From `versioning.gitlab-ci.yml`:

- `increase_version` runs when:
  - `CI_PIPELINE_SOURCE == "api"`
  - `CI_COMMIT_BRANCH == $PRODUCTION_BRANCH` (default `learningos`)
  - `MANUAL_PIPELINE_OPTIONS == "versioning"`
  - `RELEASE_PASSWORD == $DEFAULT_RELEASE_PASSWORD`
- `increase_temporary_version` runs when:
  - `CI_PIPELINE_SOURCE == "api"`
  - `MANUAL_PIPELINE_OPTIONS == "versioning"`
  - `CI_COMMIT_BRANCH != $PRODUCTION_BRANCH`

Behavior:

- Uses `melos version`
- Updates `pubspec.yaml` and `release-notes.txt`
- Pushes via `SEPARATED_ORIGIN`
- Creates release MR/tag/release (production flow)

### 3) Validation jobs (root + packages)

From `validation.gitlab-ci.yml`, each validator triggers a child template using `trigger: include`.

MR-triggered validation runs when `changes` match impacted code/template paths and `if: $CI_MERGE_REQUEST_IID`.

Manual coverage mode runs when:

- `CI_PIPELINE_SOURCE == "api"`
- `MANUAL_PIPELINE_OPTIONS == "coverage"`
- `RELEASE_PASSWORD == $DEFAULT_RELEASE_PASSWORD`
- `CI_COMMIT_BRANCH == $PRODUCTION_BRANCH`

### 4) Asset jobs

From `asset.gitlab-ci.yml`:

- `upload_translation_files` auto-runs for production submission flow:
  - `CI_PIPELINE_SOURCE == "api"`
  - `MANUAL_PIPELINE_OPTIONS == "release"`
  - tag matches `^learningos-v\d+\.\d+\.\d+$`
  - release password matches
- `update_build_number` uses the same predicate but `when: manual`.

### 5) Distribution jobs (main orchestrator for build/release)

From `distribution.gitlab-ci.yml`, all `distribute_*` jobs extend `.distribute_extension` and trigger `build.gitlab-ci.yml`.

Important rule sets:

- Manual environment build rule:
  - `CI_PIPELINE_SOURCE == "api"`
  - `MANUAL_PIPELINE_OPTIONS == "build"`
  - `TENANT_ENV == $FLAVOR`
  - branch exists
- App store auto rule:
  - `CI_PIPELINE_SOURCE == "api"`
  - `MANUAL_PIPELINE_OPTIONS == "release"`
  - tag matches `^learningos-v\d+\.\d+\.\d+$`
  - release password matches
- Tenant appstore rule is same predicate but `when: manual`.
- Pre-appstore rule is same predicate and `when: manual`.

Flavor-specific distribution jobs set:

- `FLAVOR`, `APP_NAME`, `PACKAGE_ID`
- `APP_PACKAGE_ID`
- Firebase app IDs
- `DELIVER_PROVISIONING_PROFILES`
- `GYM_EXPORT_METHOD`
- `SIGH_DEVELOPMENT` for Firebase distribution flows (`true` in `.firebase_distribution_variables_extension`)

## Child Pipeline: Build + Upload

The `build` job in `build.gitlab-ci.yml` executes end-to-end:

1. Export all environment variables used by Fastlane and tools
   - `SIGH_DEVELOPMENT` is exported **only when set** (App Store flow relies on default/non-development `sigh` behavior)
2. Install JDK/Ruby/Bundler/Flutter/Shorebird as needed
3. `bundle install` in `ios` and `android`
4. `pod install`
5. Provisioning profile workflow:
   - `fastlane sigh manage -f -e -p " "`
   - `fastlane sigh -a $APP_PACKAGE_ID`
   - `fastlane sigh -a "${APP_PACKAGE_ID}.ImageNotification"`
   - `fastlane sigh manage`
6. `fastlane build` in `ios` and `android`
7. `fastlane upload` in `ios` and `android`
8. Optional Jira comment via `scripts/jira_comment.sh`
9. Persist distributed build number for production submission
10. `after_script`: increment `build_env.yaml` build number under defined conditions

## Fastlane Usage in CI

Platform entry:

- `ios/fastlane/Fastfile` lane `build` -> `build` method from `GeneralFastFile`
- `android/fastlane/Fastfile` lane `build` -> same
- `upload` lanes similarly call shared `upload` method

Shared behavior in `GeneralFastFile`:

- `build`:
  - `ManualPipelineOptions::PATCH` -> `shorebird_patch`
  - `ManualPipelineOptions::RELEASE` -> `shorebird_release` (+ `export_ipa` for iOS)
  - otherwise -> `flutter_build` (+ `export_ipa` for iOS)
- `upload`:
  - `ManualPipelineOptions::RELEASE` -> `upload_store` (App Store/Play via `deliver`/`supply`)
  - `ManualPipelineOptions::BUILD` -> `upload_firebase_distribution`
- Shorebird specifics:
  - `shorebird_release` uses build options + explicit version options + obfuscation/split-debug-info
  - `shorebird_patch` uses `--release-version=latest --track staging`

`CommonFastfile` provides env-derived helpers:

- platform/flavor/version/build number
- manual pipeline option enum from `MANUAL_PIPELINE_OPTIONS` (`build`, `release`, `patch`)
- firebase app selection

`versioning.gitlab-ci.yml` (`increase_version`) safeguards release branch creation:

- Before creating `RELEASE_BRANCH`, it deletes same-name remote branch on `SEPARATED_ORIGIN` if it exists.

`NotificationFastfile` posts Slack notifications for:

- Firebase distribution (`send_fd_notification`)
- Store upload (`send_store_notification`)

## How to Explain "Why pipeline X ran"

When asked "why did this pipeline/job run?", use this sequence:

1. Identify pipeline source (`CI_PIPELINE_SOURCE`, MR/API/tag)
2. Identify command intent (`MANUAL_PIPELINE_OPTIONS`, `BUILD_OPTION`, `TENANT_ENV`)
3. Evaluate matching job `rules` predicates in order
4. Resolve `extends` chain to get final variables for that job
5. If job triggers child pipeline, continue in `build.gitlab-ci.yml`
6. Map to Fastlane function path (`build`/`upload` -> shared methods -> action)

## Safe Editing Guidelines

### GitLab CI YAML syntax (any `*.gitlab-ci.yml`)

Edits to the root `.gitlab-ci.yml` or any nested `*.gitlab-ci.yml` (including `.gitlab/ci_templates/*.gitlab-ci.yml`) must follow **GitLab CI/CD YAML reference** semantics, not only “valid YAML.” Plain YAML linters will not catch invalid job configuration.

**Follow GitLab’s rules for:**

| Area | Notes |
|------|--------|
| `include` | `local:`, `project:`, `file:` paths; merge behavior with parent file |
| `extends` | Merge order; later keys override earlier; job-level keys override template |
| `!reference` | Must reference an existing anchor path (e.g. `[ .anchor_name, rules ]`); wrong paths fail at lint/runtime |
| `rules` | `if` / `when` / `changes`; `when: never` vs omitting rules; interaction with `workflow:` |
| `variables` | `value` + `expand: false` where expansion must be deferred; job vs global variables |
| `trigger` | Child pipelines: `include`, `strategy: depend`, `forward: pipeline_variables` |
| `script`, `before_script`, `after_script` | Multiline blocks; shell used by runner |
| Anchors (`&` / `*`) | YAML anchors must be well-formed; GitLab also supports hidden keys starting with `.` for reusable fragments |

**Authoritative references:**

- [GitLab CI/CD YAML syntax](https://docs.gitlab.com/ee/ci/yaml/) (job keywords, `rules`, `extends`, etc.)
- [CI Lint](https://docs.gitlab.com/ee/ci/yaml/lint.html) — same validation as `glab ci lint`

Do not invent keys that are not valid GitLab job/global keywords unless they are custom variables or `variables:` entries consumed by scripts. Prefer matching patterns already used in this repo’s templates (`!reference`, `.hidden_job:` anchors, `rules` arrays).

### Validate GitLab CI YAML (`glab ci lint`)

After **any** edit to:

- `.gitlab-ci.yml`, or  
- `.gitlab/ci_templates/**/*.gitlab-ci.yml`, or  
- any other `**/.gitlab-ci.yml` file in this repo,

run from the **repository root**:

```bash
glab ci lint
```

This sends the configuration to GitLab’s CI Lint API and validates GitLab-specific syntax (`include`, `extends`, `!reference`, `rules`, `trigger`, etc.) beyond what a plain YAML parser checks.

Requirements:

- [GitLab CLI](https://gitlab.com/gitlab-org/cli) (`glab`) installed and authenticated (`glab auth login`) with access to this project.

If `glab ci lint` reports errors, fix them before committing.

---

- Keep rule predicates explicit and minimal; avoid overlapping rules without intent.
- Preserve `trigger: strategy: depend` for distribution->build chaining.
- Keep flavor variables consistent (`APP_PACKAGE_ID`, Firebase IDs, provisioning names).
- Update both iOS and Android paths when changing shared build/upload flow.
- If changing Fastlane method names, update all call sites in:
  - `GeneralFastFile`
  - `ios/fastlane/Fastfile`
  - `android/fastlane/Fastfile`

## Output Template for CI/CD Explanations

Use this response structure:

1. Trigger context (source, branch/tag, key variables)
2. Matched rule(s) with exact `if` predicate
3. Stage/job chain (root -> child pipeline)
4. Fastlane execution path (method-level)
5. Result artifacts/side effects (store upload, Firebase, Slack, Jira, build number)
