# Guard::SlimLint

[![CI](https://github.com/mike927/guard-slimlint/actions/workflows/ci.yml/badge.svg)](https://github.com/mike927/guard-slimlint/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/guard-slimlint.svg)](https://rubygems.org/gems/guard-slimlint)

Guard::SlimLint runs [slim-lint](https://github.com/sds/slim-lint) automatically
every time a Slim template is added or changed.

Requires Ruby 3.3 or newer.

## Installation

Add this to your application's Gemfile:

```ruby
group :development do
  gem 'guard-slimlint'
end
```

Then run:

```
bundle install
```

## Usage

Add the plugin to your Guardfile:

```
bundle exec guard init slimlint
```

Then start Guard:

```
bundle exec guard
```

Linting itself is configured by slim-lint, not by this plugin. Put a
`.slim-lint.yml` in your project root to choose linters and their options.

## Options

```ruby
guard :slimlint, notify_on: :change, cli: '-c config/.slim-lint.yml' do
  watch(%r{^app/views/.+\.slim$})
  watch(%r{(?:.+/)?\.slim-lint\.yml$}) { |m| File.dirname(m[0]) }
end
```

| Option | Default | Meaning |
|--------|---------|---------|
| `notify_on` | `:change` | When to send a desktop notification. One of `:change`, `:failure`, `:success`, `:both`, `:none`. |
| `all_on_start` | `true` | Lint everything once when Guard starts. |
| `halt_on_fail` | `true` | Tell Guard the task failed, so a group's `halt_on_fail` can stop the rest of it. |
| `autocorrect` | `false` | Automatically correct offences that support it using `slim-lint -a`. |
| `cli` | none | Extra arguments passed straight to slim-lint. String or Array. |

An unrecognised `notify_on` or non-boolean option raises at startup rather than silently going quiet.

### Autocorrect

Setting `autocorrect: true` automatically runs `slim-lint -a`, fixing offences that support auto-correction directly on disk. If all offences in a file are corrected, slim-lint exits with status 0 and Guard reports success. If uncorrectable offences remain, slim-lint exits with status 65 and Guard reports the remaining offences.

Because auto-correction modifies files in-place, Guard's file listener detects the disk write and re-lints the now-clean template. The default `notify_on: :change` ensures this follow-up pass stays quiet and does not send duplicate desktop notifications.

### Notifications

`:change` notifies only when the outcome flips, green to red or red to green.
Saving a broken file twenty times while you fix it produces one notification,
not twenty. `:failure` notifies on every failing run, which is the older
behaviour if you prefer it.

Notifications come from Guard itself. On macOS, add `terminal-notifier-guard`
to your Gemfile, or you will only see the terminal window title change.

### Running everything

`run_all` lints the directories Guard is watching, so a `directories` line in
your Guardfile narrows it. Without one it falls back to the whole project.

## Exit status handling

slim-lint reports its outcome with sysexits codes. This plugin treats status 65
as "offences were found" and every other non-zero status as slim-lint itself
failing, which is reported through `Guard::Compat::UI.error` with the status. A
misconfigured `.slim-lint.yml` or a crash is therefore not mistaken for a lint
failure.

## Development

```
bin/setup
bundle exec rake
```

`rake` runs RSpec and RuboCop. The repository has its own Guardfile, so
`bundle exec guard` will run the suite and the linter as you edit.

## Contributing

Bug reports and pull requests are welcome at
https://github.com/mike927/guard-slimlint. Contributors are expected to follow
the [Contributor Covenant](CODE_OF_CONDUCT.md).

## License

Available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT). See [CHANGELOG.md](CHANGELOG.md)
for release history.
