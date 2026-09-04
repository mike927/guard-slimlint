# guard-slimlint: 2026 refresh roadmap

Audit date: 2026-09-03. Last commit before the audit: 2019-11-13 (v1.3.2).
Audited on Ruby 3.2.2 / Bundler 4.0.4 against the newest dependency releases
(guard 2.20.2 from 2026-07, slim_lint 0.37.0, colorize 1.1.0, rspec 3.13).

## TL;DR

The gem is small (one 65-line class) and the idea is still valid: Guard is
alive (a release shipped two months ago) and slim_lint is maintained.
But the project as committed cannot be installed for development, its test
suite fails and deletes a tracked file, and the plugin misreports every
slim-lint crash as "offences detected". Fixing that is one short session.
Making it a gem people would pick in 2026 (CI, Ruby 3.x floor, no shelling
out, useful notifications) is another one or two days.

Recommended shape of the work: four phases, each shippable on its own,
landing as three releases. See the release plan below.

## Release plan

One thing shapes the whole split: the Bundler pin (B1) is a *development*
dependency. RubyGems never resolves it for a consumer app, so 1.3.2 installs
and runs fine for users today. It blocks contributors, not users. The bugs
users actually hit are B3 (paths with spaces) and B4 (crashes reported as lint
offences). That means there is no emergency, and the split can follow SemVer
honestly instead of racing out a hotfix.

Three releases. Ship 1.4.0 before starting 2.0.0.

| Release | Theme | Phases | Breaking | Effort |
|---------|-------|--------|----------|--------|
| 1.4.0 | It works again | 0, 1, 2 | No | about 1 day |
| 2.0.0 | Modern plugin | 3, minus autocorrect | Yes | 1-2 days |
| 2.1.0 | Autocorrect | the autocorrect option | No | about half a day |

### 1.4.0

A minor, not a patch. Error reporting changes behaviour, and `halt_on_fail`
starts working, so 1.3.3 would undersell it.

Contains every repo-hygiene fix (B1, B2, B5, B6, B7, B8), both user-visible
bugfixes (B3, B4), the grammar fix (B11), `throw :task_has_failed`, gemspec
metadata, frozen string literals, the CHANGELOG, Dependabot, and the README
corrections for the wrong `guard init` command and the `[USERNAME]` link.

Two ordering constraints inside the release:

- B1 and B2 come first. Until they land you cannot run the suite, so nothing else is verifiable.
- CI (B8) must be green *before* the tag, not after. Releasing untested is what got the gem into this state.

`required_ruby_version` goes in at `>= 3.1`, matching the CI matrix exactly.
Declaring 3.0 was tempting, because that is slim_lint's own floor, but nothing
would test it and a floor you cannot prove is a guess. Ruby 3.0 has been end of
life since April 2024.

Anyone on an older Ruby keeps 1.3.2, which still works for them.

### 2.0.0

Everything in Phase 3 except autocorrect. What makes it major:

- Ruby floor rises to 3.3, the oldest Ruby still getting security updates when this is written. Stating it as a rule rather than a number means the next release does not have to relitigate it.
- `colorize` is gone, so the `String` monkeypatch disappears from host apps.
- `run_all` stops linting `.` and uses the watched directories, which lints *fewer* files for anyone who relied on the wide sweep.
- The in-process runner changes when `.slim-lint.yml` is re-read. Guard must be reloaded after a config edit.
- `slim_lint` floor moves to `~> 0.37` for the Runner API. This re-tightens the bound 1.4.0 deliberately loosened, so it is a cost of the in-process runner rather than a free upgrade. Weigh it when deciding whether that runner is worth it at all.

Additive in the same release, because they are cheap once the runner is in
place: `config_file:`, `halt_on_fail:`, offence counts in notifications, the
new template Guardfile patterns, and the README rewrite.

Consider tagging `2.0.0.rc1` first. The in-process runner is the one change
that could break someone quietly, and a prerelease costs nothing.

### 2.1.0

The autocorrect option, alone. It is the only feature here that writes to the
files Guard is watching, so it can loop. Isolating it means a bad interaction
is one revert, not a rollback of the whole rewrite.

### What I would not do

Skip a 1.5.0 that adds `config_file:` to the subprocess design. It works, but
Phase 3 deletes that code path, so you would implement the option twice. Only
reach for 1.5.0 if 2.0.0 stalls and users need the option sooner.

### Tags

`v1.3.0` was never tagged. Backfill it against commit `2edac01` or leave it
alone, but keep `Guard::SlimLintVersion::VERSION` and the tag in step from
1.4.0 on.

## Verified bugs

Each item below was reproduced during the audit, not inferred.

| # | Bug | Where | Effect | Fix |
|---|-----|-------|--------|-----|
| B1 | Dev dependency on Bundler `~> 1.16` | `guard-slimlint.gemspec` | `bundle install` fails on every Ruby since 2.7 ("Could not find compatible versions"). Nobody can run the tests or build the gem. | Delete the Bundler dev dependency. Bundler is not declared as a dependency anymore. |
| B2 | Obsolete RuboCop config (`Metrics/LineLength`, `Documentation` without department) | `.rubocop.yml` | slim_lint's RuboCop linter aborts with `private method 'select' called for nil` (exit 70) on every file in this repo, and `rubocop` itself refuses to run. | Rename to `Layout/LineLength` and `Style/Documentation`, add `AllCops: NewCops: enable`, `TargetRubyVersion`. |
| B3 | Paths are interpolated into a shell string | `lib/guard/slimlint.rb` `run` | A file in `sp ace/` is passed as two arguments (`File path 'sp' does not exist`). Shell metacharacters in a filename would be interpreted by the shell. | `system('slim-lint', *paths)` (argv form, no shell) or call the slim_lint Ruby API (see Phase 3). |
| B4 | Every non-zero exit is reported as lint offences | `run` | slim-lint uses sysexits: 65 = lints found, 64 usage, 67 no input, 70 crash, 78 bad config. Crashes and config errors show the red "offences detected" line and a failure notification, so the real error is hidden. | Inspect `$?.exitstatus`. Only 65 is a lint failure; everything else goes to `UI.error` with the exit code. |
| B5 | Spec suite is destructive and slow | `spec/guard/slimlint_spec.rb` before/after hooks | Every example deletes the repo's own `Guardfile`, runs `bundle exec guard init` as a subprocess (24 times, ~9 s), then deletes the file again. After `rspec`, `git status` shows `D Guardfile`. | Run `guard init` only in the two init examples, inside `Dir.mktmpdir`, with `Guard::UI` silenced. Everything else needs no Guardfile at all. |
| B6 | The "clean" fixture is not clean | `spec/fixtures/testfile.html.slim` | Missing trailing newline triggers `TrailingBlankLines`, so slim-lint exits 65 and the "no offences found" example fails. | Add the newline. Also add `spec/fixtures/.slim-lint.yml` so the failing fixture does not depend on slim_lint's default line length. |
| B7 | Committed Guardfile drifts from the template | `Guardfile` vs `lib/guard/slimlint/templates/Guardfile` | Root Guardfile says `notify_on: :success`, template says `:both`; the spec overwrites the root one anyway. The root Guardfile also watches `.html.slim` files, which this repo does not have. | Make the root Guardfile a real dev Guardfile (guard-rspec + guard-rubocop) or delete it. |
| B8 | No CI | `.travis.yml` | travis-ci.org shut down in 2021, and the file targets Ruby 2.2.3. Nothing runs the tests. | GitHub Actions matrix (Phase 2). |
| B9 | Wrong and stale docs | `README.md` | "instalation", `[USERNAME]` placeholder in the contributing link, `guard init` should be `guard init slimlint`, no mention of `all_on_start` or `notify_on` options, no changelog. | README rewrite (Phase 3), CHANGELOG (Phase 2). |
| B10 | `required_ruby_version` missing | gemspec | slim_lint 0.37 needs Ruby >= 3.0, so the gem cannot work below that, but RubyGems will happily install it on 2.x and fail at runtime. | Set `required_ruby_version = '>= 3.1'` in 1.4.0, raise to `'>= 3.3'` in 2.0.0. |
| B11 | Grammar in user-facing output | `run` | "Slim offences has been detected". | "Slim offences have been detected" (or "slim-lint found N offences", Phase 3). |

Smaller findings, worth fixing while touching the files:

- `colorize` is a runtime dependency used for two `.red` / `.green` calls. It monkeypatches `String` in every host app that installs the gem, and the `~> 0.8.1` pin is three years behind. Guard already ships `Guard::Compat::UI.color` and `UI.error` / `UI.warning`, which is what other Guard plugins use.
- The plugin references bare `UI` and `Notifier`. guard-compat's documented API is `Guard::Compat::UI.info` / `Guard::Compat::UI.notify`; that is also why the spec has to `require 'guard/notifier'` by hand.
- On failure the plugin never `throw :task_has_failed`, so Guard's `halt_on_fail` group option has no effect for this plugin.
- `run_all` lints `.`, which ignores the Guardfile watch patterns and walks `node_modules`, `vendor`, `tmp` unless the user's `.slim-lint.yml` excludes them.
- No `# frozen_string_literal: true` magic comments; `bindir = 'exe'` with no `exe/` dir; no gemspec `metadata` (`source_code_uri`, `changelog_uri`, `rubygems_mfa_required`).
- GitHub issue "New gem release?" from 2018 has a contributor offering to take over maintenance. Worth answering either way once 2.0.0 is out.
- A competing gem, `guard-slim_lint` 1.2.0, exists on RubyGems. Worth a look for features to match before writing the README.

## Prioritised backlog

Scoring from the tech-debt framework: Priority = (Impact + Risk) x (6 - Effort),
each on a 1-5 scale. Effort 1 = under an hour, 5 = days.

| Item | Category | Impact | Risk | Effort | Priority |
|------|----------|--------|------|--------|----------|
| B1 drop Bundler pin | Dependency | 5 | 5 | 1 | 50 |
| B2 fix `.rubocop.yml` | Dependency | 5 | 5 | 1 | 50 |
| B6 fixtures | Test | 4 | 3 | 1 | 35 |
| B5 non-destructive specs | Test | 4 | 3 | 2 | 28 |
| B4 exit-code handling | Code | 4 | 4 | 2 | 32 |
| B3 argv-form `system` | Code | 3 | 4 | 1 | 35 |
| B8 GitHub Actions CI | Infrastructure | 4 | 4 | 2 | 32 |
| B10 `required_ruby_version` + gemspec metadata | Dependency | 3 | 4 | 1 | 35 |
| Drop `colorize`, use `Compat::UI` | Dependency | 3 | 2 | 1 | 25 |
| `throw :task_has_failed` | Code | 2 | 2 | 1 | 20 |
| Use slim_lint Ruby API, lint counts in notifications | Code / Feature | 4 | 2 | 3 | 18 |
| B9 README rewrite + CHANGELOG | Documentation | 3 | 2 | 2 | 20 |
| B7 dev Guardfile | Code | 1 | 1 | 1 | 10 |
| Dependabot / release automation | Infrastructure | 2 | 3 | 2 | 20 |

## Phase 0: make it buildable again (about 2 hours, part of 1.4.0)

Goal: `bundle install && bundle exec rspec && bundle exec rubocop` all green on Ruby 3.x.

1. Remove the Bundler dev dependency from the gemspec (B1). Bump `rake` to `~> 13.0`, `rspec` to `~> 3.13`.
2. Replace `.rubocop.yml` (B2):
   ```yaml
   AllCops:
     NewCops: enable
     TargetRubyVersion: 3.1
     SuggestExtensions: false
   Style/Documentation:
     Enabled: false
   Layout/LineLength:
     Max: 120
   ```
   Add `rubocop`, `rubocop-rake`, `rubocop-rspec` as dev dependencies (slim_lint already pulls rubocop in at runtime, so pinning it is free).
3. Add the trailing newline to both fixtures and a `spec/fixtures/.slim-lint.yml` with an explicit `LineLength: max: 80` (B6).
4. Rewrite the spec hooks (B5): the two "initialization guard" examples get their own `describe` that creates a temp dir, copies nothing, runs `Guard::CLI` or the `guard init slimlint` subprocess there, and asserts on that file. All other examples stop touching the filesystem.
5. Fix the "has been" grammar (B11) and update the matching expectation.
6. Delete `.travis.yml`.

Verification: `git status` is clean after `bundle exec rspec`; suite runs in well under a second apart from the two init examples.

## Phase 1: correctness (about half a day, ships with 1.4.0)

1. Replace the shell string with the argv form of `system` (B3). Keep the executable name resolvable through `bundle exec` as today.
2. Read `$?.exitstatus` after the call (B4):
   - 0: success path.
   - 65: lint offences (the only "failure" case for notifications).
   - anything else: `UI.error "slim-lint exited with status N"`, notification with image `:failed` only if `notify_on` is `:failure` or `:both`, and `throw :task_has_failed`.
   Add a spec per exit code by stubbing `system` and `$?` (or wrap the call in a small `Runner` object that returns a status, which is easier to stub).
3. `throw :task_has_failed` after reporting a lint failure so `halt_on_fail` works. Guard rescues it; nothing else changes.
4. Deferred to 2.0.0: making `run_all` honour the watched directories instead of `.`. It lints fewer files than before, so it does not belong in a backwards-compatible release.
5. Tests for `run_on_additions` and `run_all` (currently only `run_on_modifications` and `start` are exercised end-to-end).

Do not tag yet. Phase 2 adds the CI that has to be green before the 1.4.0 release.

## Phase 2: modern toolchain (about half a day, completes 1.4.0)

1. GitHub Actions workflow `ci.yml`: `ruby/setup-ruby` with `bundler-cache: true`, matrix over 3.1, 3.2, 3.3 and 3.4, jobs for `rspec` and `rubocop`. Add the badge to the README. 3.1 and 3.2 are past end of life, and they are in the matrix on purpose: 1.4.0 exists to get bugfixes to people who already have the gem, and some of them are on an old stack. Two CI rows is a cheap price for not locking them out.
2. Gemspec hygiene (B10 and the smaller findings):
   - `required_ruby_version = '>= 3.1'` for 1.4.0, matching the CI matrix. 2.0.0 raises it to 3.3.
   - `metadata` with `source_code_uri`, `changelog_uri`, `bug_tracker_uri`, `rubygems_mfa_required: 'true'`.
   - `spec.files` via `Dir.glob` instead of `git ls-files` so the gem builds from a tarball too.
   - Remove `bindir` / `executables`.
   - Loosen `guard` to `~> 2.14` only (drop the `>= 2.14.2` second clause, it is implied by any version resolvable today) and `slim_lint` to `>= 0.20, < 2.0`. The upper bound matters more here than it looks: slim_lint has sat on 0.x for a decade, so `< 1.0` would let a routine maturity release lock out every user of this gem until a new release ships. The plugin only touches the executable name and its exit codes, so the compatible range is genuinely wide. guard-brakeman drops the upper bound entirely; `< 2.0` is the same idea with a backstop.
3. `# frozen_string_literal: true` everywhere (rubocop `-a` does it).
4. `CHANGELOG.md` in Keep a Changelog format, backfilled from the git tags (1.3.0, 1.3.1, 1.3.2, then Unreleased).
5. `.github/dependabot.yml` for `bundler` and `github-actions` ecosystems, weekly.
6. Replace the root `Guardfile` with a dev one (`guard-rspec`, `guard-rubocop`) or remove it (B7). Remove `bin/setup`'s `set -vx` noise or leave as is; it is harmless.
7. Modernise `bin/console` to `require 'irb'` only (it already does) and drop the pry comment.

## Phase 3: feature refresh (1-2 days, releases 2.0.0 and 2.1.0)

This is where the gem becomes worth choosing over running `slim-lint` in a
terminal by hand.

1. Call slim_lint in-process instead of shelling out. `SlimLint::Runner.new.run(files: paths, config_file: ...)` returns a `SlimLint::Report` with `lints` and `failed?`. Print it through `SlimLint::Reporter::DefaultReporter` (the same output the CLI produces) and use `report.lints.size` in the notification: "3 slim-lint offences in 2 files" is far more useful than "Slim offences detected". Benefits: no PATH dependency, no subprocess per save, the user's `.slim-lint.yml` `exclude` list is honoured automatically, and B3 disappears entirely. Cost: slim_lint is loaded into the Guard process, so a change to `.slim-lint.yml` needs a Guard reload; document it and implement `reload` to clear any cached config.
2. Options, all documented in the template Guardfile and README:
   - `notify_on:` (existing) `:failure | :success | :both | :none`.
   - `all_on_start:` (existing).
   - `config_file:` path to a non-default `.slim-lint.yml`.
   - `halt_on_fail:` whether to `throw :task_has_failed` (default true).
   - `autocorrect:` ships separately in 2.1.0. slim_lint 0.37 supports it in the runner; opt-in, off by default, because it rewrites files while Guard is watching them (guard-rubocop handles the same loop, copy its approach).
   - Drop `cli:` string passthrough; it only makes sense with the subprocess design.
3. Switch every `UI` / `Notifier` call to `Guard::Compat::UI` and drop `colorize` (the `Compat::UI.color` helper covers it). Remove `require 'colorize'` from the spec.
4. Template Guardfile: watch `%r{^app/views/.+\.slim$}` (Rails, the common case) plus a commented generic pattern, and `%r{^\.slim-lint\.yml$}` to trigger `run_all`.
5. README rewrite (B9): badges, install, `guard init slimlint`, options table, notification setup (terminal-notifier-guard on macOS, which is what the closed issue #4 concluded), compatibility table, contributing, changelog link. Fix the `[USERNAME]` link.
6. Spec cleanup: `rubocop-rspec` compliant, `described_class`, `instance_double` for the runner, no `send(:private_method)` (test through `run_on_modifications` with stubbed report instead).

Breaking changes that justify 2.0.0: Ruby >= 3.3, `colorize` no longer loaded into the host app, `run_all` scope, `halt_on_fail` default.

## Phase 4: release and maintenance (an hour, then ongoing)

1. Enable MFA on the RubyGems account and use `rake release` (already provided by `bundler/gem_tasks`), or a `release.yml` workflow with RubyGems trusted publishing so releases come from a tag push.
2. Tag `v1.4.0` after Phase 2, `v2.0.0` and `v2.1.0` after Phase 3, per the release plan above.
3. Answer the 2018 "New gem release?" issue and decide whether to add the volunteer as a co-maintainer on GitHub and RubyGems. A second owner is the cheapest insurance the gem does not go stale again.
4. Dependabot PRs auto-merge for dev dependencies if CI is green (optional).

## What not to do

- Do not rewrite the version constant location. `Guard::SlimLintVersion` looks odd but it is the pattern guard-rspec uses so the gemspec can load the version without loading Guard.
- Do not add a `.slim-lint.yml` to the gem for users. Configuration belongs to the host project; the gem only forwards `config_file:`.
- Do not keep both the subprocess and the in-process runner. Pick the API (Phase 3) and delete the `system` path; two code paths for one feature is how the exit-code bug happened.
