# frozen_string_literal: true

require 'spec_helper'
require 'guard/notifier'
require 'guard/compat/test/helper'
require 'guard/slimlint'

RSpec.describe Guard::SlimLint do
  subject(:plugin) { described_class.new(notify_on: :none) }

  before do
    allow(Guard::Compat::UI).to receive(:info)
    allow(Guard::Compat::UI).to receive(:error)
    allow(Guard::Compat::UI).to receive(:notify)
  end

  # Reporting is driven entirely by the slim-lint exit status, so stubbing it
  # covers every status without shelling out.
  def run_with_status(status, paths: ['a.html.slim'])
    allow(plugin).to receive(:lint).and_return(status)
    catch(:task_has_failed) { plugin.run_on_modifications(paths) }
  end

  describe 'reporting the lint outcome' do
    it 'reports success when slim-lint exits 0' do
      expect(Guard::Compat::UI).to receive(:info).with(a_string_including('No Slim offences detected'))
      run_with_status(0)
    end

    it 'reports offences when slim-lint exits 65' do
      expect(Guard::Compat::UI).to receive(:info).with(a_string_including('Slim offences have been detected'))
      run_with_status(65)
    end

    # Regression test for the 1.3.x bug where any non-zero status was reported
    # as lint offences, hiding crashes, usage errors and bad configuration.
    [[64, 'usage error'], [67, 'missing input'], [70, 'crash'], [78, 'bad config']].each do |status, description|
      it "reports a #{description} (status #{status}) as an error, not as offences" do
        expect(Guard::Compat::UI).to receive(:error).with("slim-lint exited with status #{status}")
        expect(Guard::Compat::UI).not_to receive(:info)
        run_with_status(status)
      end
    end

    it 'reports an error when slim-lint never ran' do
      expect(Guard::Compat::UI).to receive(:error).with('slim-lint could not be run')
      run_with_status(nil)
    end

    # Bundler exits 1 and a shell exits 127, neither of which mentions Slim, so
    # the bare number used to send people looking for lint errors in templates
    # that were fine.
    it 'explains status 1 as a bundle problem rather than a bare number' do
      expect(Guard::Compat::UI).to receive(:error)
        .with('slim-lint exited with status 1: the bundle is probably out of sync, try bundle install')
      run_with_status(1)
    end

    it 'explains status 127 as a missing binary' do
      expect(Guard::Compat::UI).to receive(:error)
        .with('slim-lint exited with status 127: slim-lint is not on PATH, check that the gem is installed')
      run_with_status(127)
    end
  end

  describe 'halting the Guard task' do
    it 'does not halt when the run succeeds' do
      allow(plugin).to receive(:lint).and_return(0)
      expect { plugin.run_on_modifications(['a.html.slim']) }.not_to throw_symbol(:task_has_failed)
    end

    it 'halts when offences are found' do
      allow(plugin).to receive(:lint).and_return(65)
      expect { plugin.run_on_modifications(['a.html.slim']) }.to throw_symbol(:task_has_failed)
    end

    it 'halts when slim-lint fails to run' do
      allow(plugin).to receive(:lint).and_return(70)
      expect { plugin.run_on_modifications(['a.html.slim']) }.to throw_symbol(:task_has_failed)
    end

    it 'stays silent for Guard when :halt_on_fail is disabled' do
      plugin = described_class.new(notify_on: :none, halt_on_fail: false)
      allow(plugin).to receive(:lint).and_return(65)

      expect { plugin.run_on_modifications(['a.html.slim']) }.not_to throw_symbol(:task_has_failed)
    end
  end

  describe 'notification modes' do
    describe ':change' do
      subject(:plugin) { described_class.new(notify_on: :change) }

      it 'stays quiet when the first run is already clean' do
        expect(Guard::Compat::UI).not_to receive(:notify)
        run_with_status(0)
      end

      it 'notifies once when a green project turns red, then stays quiet' do
        expect(Guard::Compat::UI).to receive(:notify).once

        run_with_status(65)
        run_with_status(65)
        run_with_status(65)
      end

      it 'notifies again when the outcome flips back to green' do
        expect(Guard::Compat::UI).to receive(:notify).twice

        run_with_status(65)
        run_with_status(0)
        run_with_status(0)
      end

      it 'treats a slim-lint failure as a change away from green' do
        expect(Guard::Compat::UI).to receive(:notify)
          .with('slim-lint exited with status 78', hash_including(image: :failed))

        run_with_status(78)
      end
    end

    {
      none: { success: 0, failure: 0 },
      both: { success: 1, failure: 1 },
      failure: { success: 0, failure: 1 },
      success: { success: 1, failure: 0 }
    }.each do |mode, expected|
      describe ":#{mode}" do
        subject(:plugin) { described_class.new(notify_on: mode) }

        it "notifies #{expected[:success]} time(s) when no offences are found" do
          expect(Guard::Compat::UI).to receive(:notify).exactly(expected[:success]).times
          run_with_status(0)
        end

        it "notifies #{expected[:failure]} time(s) when offences are found" do
          expect(Guard::Compat::UI).to receive(:notify).exactly(expected[:failure]).times
          run_with_status(65)
        end
      end
    end

    it 'defaults to notifying only on a change' do
      expect(described_class.new.notify_on).to eq(:change)
    end

    # `guard init slimlint` writes the template verbatim, so a default there
    # that contradicts the plugin's own would hand every new user a setting
    # neither the README nor this class documents.
    it 'ships a template whose notify_on matches that default' do
      template = File.read(SlimLintFixtures::TEMPLATE_GUARDFILE)

      expect(template).to include("notify_on: #{described_class.new.notify_on.inspect}")
    end

    it 'ships a template whose commented autocorrect matches that default' do
      template = File.read(SlimLintFixtures::TEMPLATE_GUARDFILE)

      expect(template).to include("autocorrect:  #{described_class.new.autocorrect} (default)")
    end
  end

  describe 'option validation' do
    it 'rejects an unrecognised :notify_on instead of silently staying quiet' do
      expect { described_class.new(notify_on: :failur) }
        .to raise_error(ArgumentError, /unknown :notify_on :failur/)
    end

    it 'accepts every documented mode' do
      expect { described_class::NOTIFY_MODES.each { |m| described_class.new(notify_on: m) } }
        .not_to raise_error
    end

    it 'rejects an invalid :autocorrect value' do
      expect { described_class.new(autocorrect: :yes) }
        .to raise_error(ArgumentError, /:autocorrect must be true or false/)
    end

    it 'rejects a non-boolean :all_on_start value' do
      expect { described_class.new(all_on_start: 'true') }
        .to raise_error(ArgumentError, /:all_on_start must be true or false/)
    end

    it 'rejects a non-boolean :halt_on_fail value' do
      expect { described_class.new(halt_on_fail: 'false') }
        .to raise_error(ArgumentError, /:halt_on_fail must be true or false/)
    end

    it 'accepts boolean option values' do
      expect { [true, false].each { |v| described_class.new(autocorrect: v, all_on_start: v, halt_on_fail: v) } }
        .not_to raise_error
    end
  end

  describe '#start' do
    it 'runs all when :all_on_start is enabled' do
      plugin = described_class.new(all_on_start: true)
      expect(plugin).to receive(:run_all)
      plugin.start
    end

    it 'does nothing when :all_on_start is disabled' do
      plugin = described_class.new(all_on_start: false)
      expect(plugin).not_to receive(:run_all)
      plugin.start
    end

    it 'runs all by default' do
      plugin = described_class.new
      expect(plugin).to receive(:run_all)
      plugin.start
    end
  end

  describe 'invoking the real slim-lint binary' do
    it 'passes a clean template' do
      in_slim_project do
        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('No Slim offences detected'))
        catch(:task_has_failed) { plugin.run_on_modifications(['clean.html.slim']) }
      end
    end

    it 'reports offences in a failing template' do
      in_slim_project do
        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('Slim offences have been detected'))
        catch(:task_has_failed) { plugin.run_on_modifications(['failing.html.slim']) }
      end
    end

    # Regression test for the 1.3.x bug where paths were interpolated into a
    # shell string, so "sp ace/x.slim" reached slim-lint as two arguments.
    it 'lints a path containing a space' do
      in_slim_project do |dir|
        FileUtils.mkdir(File.join(dir, 'sp ace'))
        FileUtils.cp('clean.html.slim', File.join(dir, 'sp ace', 'clean.html.slim'))

        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('No Slim offences detected'))
        catch(:task_has_failed) { plugin.run_on_modifications(['sp ace/clean.html.slim']) }
      end
    end

    it 'lints additions the same way as modifications' do
      in_slim_project do
        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('No Slim offences detected'))
        catch(:task_has_failed) { plugin.run_on_additions(['clean.html.slim']) }
      end
    end
  end

  describe ':cli option' do
    # A config strict enough that even the clean fixture breaks it, so reaching
    # slim-lint is the only way the run can fail.
    def write_strict_config(dir)
      File.write(File.join(dir, 'strict.yml'), "linters:\n  LineLength:\n    max: 5\n")
    end

    it 'forwards a String of arguments to slim-lint' do
      in_slim_project do |dir|
        write_strict_config(dir)
        plugin = described_class.new(notify_on: :none, cli: '-c strict.yml')

        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('Slim offences have been detected'))
        catch(:task_has_failed) { plugin.run_on_modifications(['clean.html.slim']) }
      end
    end

    it 'forwards an Array of arguments to slim-lint' do
      in_slim_project do |dir|
        write_strict_config(dir)
        plugin = described_class.new(notify_on: :none, cli: ['-c', 'strict.yml'])

        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('Slim offences have been detected'))
        catch(:task_has_failed) { plugin.run_on_modifications(['clean.html.slim']) }
      end
    end

    it 'lints normally when no :cli is given' do
      in_slim_project do
        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('No Slim offences detected'))
        catch(:task_has_failed) { plugin.run_on_modifications(['clean.html.slim']) }
      end
    end
  end

  describe ':autocorrect option' do
    it 'defaults to false' do
      expect(described_class.new.autocorrect).to be false
    end

    it 'passes -a to slim-lint when autocorrect is enabled' do
      plugin = described_class.new(notify_on: :none, autocorrect: true)
      allow(plugin).to receive(:system).with('slim-lint', '-a', 'clean.html.slim') { system('true') }
      expect { plugin.run_on_modifications(['clean.html.slim']) }.not_to throw_symbol(:task_has_failed)
    end

    it 'does not duplicate -a when already present in cli string' do
      plugin = described_class.new(notify_on: :none, autocorrect: true, cli: '-a -c strict.yml')
      allow(plugin).to receive(:system).with('slim-lint', '-a', '-c', 'strict.yml', 'a.slim') { system('true') }
      expect { plugin.run_on_modifications(['a.slim']) }.not_to throw_symbol(:task_has_failed)
    end

    it 'does not duplicate -a when --auto-correct is present in cli array' do
      plugin = described_class.new(notify_on: :none, autocorrect: true, cli: ['--auto-correct'])
      allow(plugin).to receive(:system).with('slim-lint', '--auto-correct', 'clean.html.slim') { system('true') }
      expect { plugin.run_on_modifications(['clean.html.slim']) }.not_to throw_symbol(:task_has_failed)
    end

    it 'does not pass -a when autocorrect is disabled' do
      plugin = described_class.new(notify_on: :none, autocorrect: false)
      allow(plugin).to receive(:system).with('slim-lint', 'clean.html.slim') { system('true') }
      expect { plugin.run_on_modifications(['clean.html.slim']) }.not_to throw_symbol(:task_has_failed)
    end

    it 'automatically corrects fixable offences in files on disk' do
      in_slim_project do |dir|
        dirty = File.join(dir, 'fixable.html.slim')
        File.write(dirty, "div\n  p Hello world   \n")
        plugin = described_class.new(notify_on: :none, autocorrect: true)
        expect { plugin.run_on_modifications([dirty]) }.not_to throw_symbol(:task_has_failed)
        expect(File.read(dirty)).to eq("div\n  p Hello world\n")
      end
    end

    it 'partially corrects fixable offences but halts if unfixable offences remain' do
      in_slim_project do |dir|
        mixed = File.join(dir, 'mixed.html.slim')
        File.write(mixed, "div\n  p #{'a' * 150}   \n")
        plugin = described_class.new(notify_on: :none, autocorrect: true)
        expect { plugin.run_on_modifications([mixed]) }.to throw_symbol(:task_has_failed)
        expect(File.read(mixed)).to eq("div\n  p #{'a' * 150}\n")
      end
    end

    it 'leaves fixable offences untouched when autocorrect is false' do
      in_slim_project do |dir|
        dirty = File.join(dir, 'fixable.html.slim')
        File.write(dirty, "div\n  p Hello world   \n")
        plugin = described_class.new(notify_on: :none, autocorrect: false)
        catch(:task_has_failed) { plugin.run_on_modifications([dirty]) }
        expect(File.read(dirty)).to eq("div\n  p Hello world   \n")
      end
    end
  end

  describe '#run_all' do
    it 'lints the directories Guard was told to watch' do
      in_slim_project do |dir|
        FileUtils.mkdir(File.join(dir, 'tidy'))
        FileUtils.cp('clean.html.slim', File.join(dir, 'tidy', 'clean.html.slim'))
        allow(Guard::Compat).to receive(:watched_directories).and_return([Pathname('tidy')])

        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('No Slim offences detected'))
        catch(:task_has_failed) { plugin.run_all }
      end
    end

    it 'sees offences that live inside a watched directory' do
      in_slim_project do
        allow(Guard::Compat).to receive(:watched_directories).and_return([Pathname('.')])

        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('Slim offences have been detected'))
        catch(:task_has_failed) { plugin.run_all }
      end
    end

    it 'falls back to the whole project when Guard watches nothing in particular' do
      in_slim_project do
        allow(Guard::Compat).to receive(:watched_directories).and_return([])

        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('Slim offences have been detected'))
        catch(:task_has_failed) { plugin.run_all }
      end
    end

    # guard-compat refuses to answer unless Guard's CLI is loaded, which is the
    # case whenever the plugin is driven programmatically instead of by `guard`.
    it 'falls back to the whole project when Guard is not fully loaded' do
      in_slim_project do
        allow(Guard::Compat).to receive(:watched_directories).and_raise(NotImplementedError)

        expect(Guard::Compat::UI).to receive(:info).with(a_string_including('Slim offences have been detected'))
        expect { catch(:task_has_failed) { plugin.run_all } }.not_to raise_error
      end
    end
  end
end
