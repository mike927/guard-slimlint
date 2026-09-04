# Guard::SlimLint

[![CI](https://github.com/mike927/guard-slimlint/actions/workflows/ci.yml/badge.svg)](https://github.com/mike927/guard-slimlint/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/guard-slimlint.svg)](https://rubygems.org/gems/guard-slimlint)

Guard::SlimLint runs [slim-lint](https://github.com/sds/slim-lint) automatically
every time a Slim template is added or changed.

Requires Ruby 3.1 or newer.

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

Or install it yourself:

```
gem install guard-slimlint
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
guard :slimlint, notify_on: :failure, all_on_start: true do
  watch(%r{^app/views/.+\.slim$})
end
```

| Option | Default | Meaning |
|--------|---------|---------|
| `notify_on` | `:failure` | When to send a desktop notification. One of `:failure`, `:success`, `:both`, `:none`. |
| `all_on_start` | `true` | Lint everything once when Guard starts. |

Desktop notifications come from Guard itself. On macOS, add
`terminal-notifier-guard` to your Gemfile to get them.

Guard's `halt_on_fail` group option is respected. Put the plugin in a group with
`halt_on_fail: true` to stop the rest of the group when linting fails.

## Exit status handling

slim-lint reports its outcome with sysexits codes. This plugin treats status 65
as "offences were found" and every other non-zero status as slim-lint itself
failing, which is reported through `Guard::UI.error` with the status. A
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
