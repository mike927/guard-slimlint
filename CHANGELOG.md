# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2026-09-14

### Added

- `autocorrect:` option, default `false`, to automatically correct offences that
  support it using `slim-lint -a`. Offences are corrected in-place on disk. If all
  offences are corrected, the run succeeds cleanly.
- Non-boolean values passed to `autocorrect:`, `all_on_start:`, or `halt_on_fail:`
  raise an `ArgumentError` on startup.

## [2.0.0] - 2026-09-07

A behaviour release. The plugin still runs slim-lint as a subprocess, which
was a deliberate decision: Guard is a long-running process, and loading the
linter into it would freeze `.slim-lint.yml` at startup and let RuboCop's
caches grow all day. Four of the five comparable Guard plugins shell out for
the same reason.

### Changed

- **`notify_on` now defaults to `:change`.** Notifications fire only when the
  outcome flips, green to red or red to green. Saving a broken template twenty
  times while fixing it produces one notification instead of twenty. Pass
  `notify_on: :failure` for the old behaviour.
- **Ruby 3.3 or newer is required.** 3.2 reached end of life in March 2026.
- **`run_all` lints the directories Guard watches** rather than always
  sweeping `.`. A `directories` line in your Guardfile now narrows it. Without
  one, behaviour is unchanged.
- The Guardfile template watches `app/views` rather than every `.html.slim`
  file anywhere in the project, and re-lints when `.slim-lint.yml` changes.
- Option readers are no longer writable. `notify_on` and `all_on_start` are
  read once at construction, so the writers only ever looked useful.

### Added

- `cli:` option, forwarding arbitrary arguments to slim-lint as a String or an
  Array. This covers `-c`, linter selection and anything slim-lint adds later
  without a new option here for each.
- `halt_on_fail:` option, default `true`, to opt out of failing Guard's task.
- An unrecognised `notify_on` now raises at startup instead of silently
  disabling notifications for the whole session.
- Exit statuses that do not come from slim-lint itself now explain themselves.
  Status 1 is Bundler failing to load the command, and 127 is a missing binary;
  neither mentions Slim, so the bare number used to send people hunting for
  lint errors in templates that were fine.

### Removed

- The `colorize` runtime dependency. It monkeypatched `String` in every host
  application to colour two log lines. Guard's own `Compat::UI.color` does the
  same job, so the plugin now adds nothing to your object space.

## [1.4.0] - 2026-09-04

The gem had not been touched since 2019 and could no longer be developed on any
supported Ruby. This release makes it buildable, testable and correct again
without changing the plugin's interface.

### Fixed

- slim-lint failures are no longer reported as lint offences. slim-lint uses
  sysexits codes, and only status 65 means offences were found. Crashes, usage
  errors, missing files and bad configuration now go to `Guard::UI.error` with
  the exit status instead of printing the red "offences detected" line.
- Paths are passed to slim-lint as separate arguments rather than interpolated
  into a shell string, so files whose names contain spaces or shell
  metacharacters are linted correctly.
- The plugin throws `:task_has_failed` when a run fails, so Guard's
  `halt_on_fail` group option now works.
- `bundle install` works again. The gemspec required Bundler 1.x, which no Ruby
  since 2.7 ships.
- `.rubocop.yml` used the long-since-renamed `Metrics/LineLength` cop, which
  crashed slim-lint's RuboCop linter on every file in this repository.
- The spec suite no longer deletes the repository's own `Guardfile` on every
  example, and runs in about four seconds instead of ten.
- Corrected "Slim offences has been detected" to "have been detected".
- The Guardfile template written by `guard init slimlint` used
  `notify_on: :both`, the noisiest of the four settings, contradicting the
  plugin's own `:failure` default. Every new user got a desktop notification
  on every successful save. The template now matches the documented default,
  and a spec keeps the two in step.

### Added

- GitHub Actions CI covering Ruby 3.1 through 3.4, plus RuboCop.
- Dependabot configuration for Bundler and GitHub Actions.
- This changelog.
- Regression tests for every slim-lint exit status, for paths containing
  spaces, and for `run_on_additions` and `run_all`.

### Changed

- `required_ruby_version` is now declared as `>= 3.1`.
- Dependencies relaxed and modernised: `slim_lint` `>= 0.20, < 2.0`,
  `colorize` `>= 0.8, < 2.0`, `rake` 13, `rspec` 3.13.
- Gemspec now carries `metadata` links and requires MFA for releases, and
  builds its file list with `Dir.glob` rather than `git ls-files`.

### Removed

- Travis CI configuration. travis-ci.org shut down in 2021.

## [1.3.2] - 2019-11-13

### Fixed

- Corrected the maintainer email address.

## [1.3.1] - 2019-11-13

### Changed

- Bumped the `slim_lint` dependency to 0.15.

## [1.3.0] - 2018-04-15

### Fixed

- `all_on_start` is honoured, so the plugin no longer lints everything on
  startup when the option is disabled.

[Unreleased]: https://github.com/mike927/guard-slimlint/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/mike927/guard-slimlint/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/mike927/guard-slimlint/compare/v1.4.0...v2.0.0
[1.4.0]: https://github.com/mike927/guard-slimlint/compare/v1.3.2...v1.4.0
[1.3.2]: https://github.com/mike927/guard-slimlint/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/mike927/guard-slimlint/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/mike927/guard-slimlint/releases/tag/v1.3.0
