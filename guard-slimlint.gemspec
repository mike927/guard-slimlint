# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guard/slimlint/version'

Gem::Specification.new do |spec|
  spec.name        = 'guard-slimlint'
  spec.version     = Guard::SlimLintVersion::VERSION
  spec.authors     = ['Michal Gajowiak']
  spec.email       = ['michal.gajowiak.927@gmail.com']

  spec.summary     = 'Guard plugin that runs slim-lint automatically'
  spec.description = 'Runs slim-lint every time a Slim template is added or modified, ' \
                     'and reports the result through Guard notifications.'
  spec.homepage    = 'https://github.com/mike927/guard-slimlint'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 3.1'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/master/CHANGELOG.md",
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir.glob(%w[lib/**/*.rb lib/**/templates/Guardfile CHANGELOG.md README.md LICENSE.txt])
  spec.require_paths = ['lib']

  spec.add_dependency 'colorize', '>= 0.8', '< 2.0'
  spec.add_dependency 'guard', '~> 2.14'
  spec.add_dependency 'guard-compat', '~> 1.2'
  # Deliberately loose. The plugin only depends on the slim-lint executable
  # and its sysexits codes, which is a tiny surface, so a slim_lint 1.0 must
  # not block every user of this gem until a new release ships here.
  spec.add_dependency 'slim_lint', '>= 0.20', '< 2.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.75'
  spec.add_development_dependency 'rubocop-rake', '~> 0.7'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'
end
