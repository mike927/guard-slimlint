# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/mike927/guard-slimlint/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/mike927/guard-slimlint/compare/v1.3.2...v1.4.0
[1.3.2]: https://github.com/mike927/guard-slimlint/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/mike927/guard-slimlint/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/mike927/guard-slimlint/releases/tag/v1.3.0
