# frozen_string_literal: true

require 'spec_helper'

# `guard init` is exercised in a subprocess on purpose. Loading real Guard into
# this process would replace the Plugin stub that guard-compat installs for the
# unit specs, so the two cannot share an interpreter.
RSpec.describe 'guard init slimlint' do
  around do |example|
    Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
  end

  let(:template) { File.read(SlimLintFixtures::TEMPLATE_GUARDFILE) }

  def guard_init
    ok = system(
      { 'BUNDLE_GEMFILE' => SlimLintFixtures::GEMFILE },
      'bundle', 'exec', 'guard', 'init', 'slimlint',
      out: File::NULL, err: File::NULL
    )
    raise "guard init failed with status #{$CHILD_STATUS&.exitstatus}" unless ok

    File.read('Guardfile')
  end

  it 'creates a Guardfile containing the plugin template' do
    expect(guard_init).to include(template)
  end

  it 'appends the template to a Guardfile that already exists' do
    File.write('Guardfile', "# existing content\n")

    expect(guard_init).to include('# existing content').and include(template)
  end
end
