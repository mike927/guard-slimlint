# frozen_string_literal: true

# Development Guardfile for this repository. It watches the gem's own code, not
# Slim templates. For the plugin's user-facing template see
# lib/guard/slimlint/templates/Guardfile.
guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/.+\.rb$}) { 'spec' }
  watch('spec/spec_helper.rb') { 'spec' }
end

guard :rubocop, all_on_start: false do
  watch(/.+\.rb$/)
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end
