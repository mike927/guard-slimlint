#!/usr/bin/env ruby
# frozen_string_literal: true

# Prints the CHANGELOG.md section for one version, so a release workflow can
# turn a tag into GitHub release notes without anyone retyping them.
#
#   ruby script/changelog_section.rb 2.0.0

version = ARGV[0].to_s.sub(/\Av/, '')
abort("usage: #{$PROGRAM_NAME} VERSION") if version.empty?

changelog = File.expand_path('../CHANGELOG.md', __dir__)
text = File.read(changelog)

# Everything between this version's heading and whatever ends it: the next
# version heading, the link definitions at the bottom, or the end of file.
section = text[/^\#\# \[#{Regexp.escape(version)}\][^\n]*\n(.*?)(?=^\#\# \[|^\[[^\]]+\]: |\z)/m, 1]
abort("no CHANGELOG section for #{version}") if section.nil? || section.strip.empty?

puts section.strip
