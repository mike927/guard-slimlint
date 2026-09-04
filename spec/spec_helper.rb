# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'English'
require 'fileutils'
require 'tmpdir'

module SlimLintFixtures
  FIXTURES = File.expand_path('fixtures', __dir__)
  CLEAN = File.join(FIXTURES, 'testfile.html.slim')
  FAILING = File.join(FIXTURES, 'failfile.html.slim')
  CONFIG = File.join(FIXTURES, '.slim-lint.yml')
  RUBOCOP_CONFIG = File.join(FIXTURES, '.rubocop.yml')
  TEMPLATE_GUARDFILE = File.expand_path('../lib/guard/slimlint/templates/Guardfile', __dir__)
  GEMFILE = File.expand_path('../Gemfile', __dir__)

  # Builds a throwaway project containing the fixtures and a slim-lint config,
  # then yields with it as the working directory. Nothing in the repository is
  # touched, so the suite leaves the working tree clean.
  def in_slim_project
    Dir.mktmpdir do |dir|
      FileUtils.cp(CLEAN, File.join(dir, 'clean.html.slim'))
      FileUtils.cp(FAILING, File.join(dir, 'failing.html.slim'))
      FileUtils.cp(CONFIG, File.join(dir, '.slim-lint.yml'))
      FileUtils.cp(RUBOCOP_CONFIG, File.join(dir, '.rubocop.yml'))
      Dir.chdir(dir) { yield dir }
    end
  end
end

RSpec.configure do |config|
  config.include SlimLintFixtures
  config.disable_monkey_patching!
  config.order = :random
end
