# frozen_string_literal: true

require 'spec_helper'
require 'guard/notifier'
require 'guard/compat/test/helper'
require 'guard/slimlint'
require 'colorize'

RSpec.describe Guard::SlimLint do
  subject(:plugin) { described_class.new(notify_on: :none) }

  # Reporting is driven entirely by the slim-lint exit status, so stubbing it
  # lets every status be covered without shelling out.
  def run_with_status(status, paths: ['a.html.slim'])
    allow(plugin).to receive(:lint).and_return(status)
    catch(:task_has_failed) { plugin.run_on_modifications(paths) }
  end

  describe 'reporting the lint outcome' do
    it 'reports success when slim-lint exits 0' do
      expect(Guard::UI).to receive(:info).with('No Slim offences detected'.green)
      run_with_status(0)
    end

    it 'reports offences when slim-lint exits 65' do
      expect(Guard::UI).to receive(:info).with('Slim offences have been detected'.red)
      run_with_status(65)
    end

    # Regression test for the bug where any non-zero status was reported as
    # lint offences, hiding crashes, usage errors and bad configuration.
    [[64, 'usage error'], [67, 'missing input'], [70, 'crash'], [78, 'bad config'],
     [127, 'binary not on PATH']].each do |status, description|
      it "reports a #{description} (status #{status}) as an error, not as offences" do
        expect(Guard::UI).to receive(:error).with("slim-lint exited with status #{status}")
        expect(Guard::UI).not_to receive(:info)
        run_with_status(status)
      end
    end

    it 'reports an error when slim-lint never ran' do
      expect(Guard::UI).to receive(:error).with('slim-lint could not be run')
      run_with_status(nil)
    end
  end

  describe 'halting the Guard task' do
    before do
      allow(Guard::UI).to receive(:info)
      allow(Guard::UI).to receive(:error)
    end

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
  end

  describe 'invoking the real slim-lint binary' do
    before { allow(Guard::UI).to receive(:info) }

    it 'passes a clean template' do
      in_slim_project do
        expect(Guard::UI).to receive(:info).with('No Slim offences detected'.green)
        catch(:task_has_failed) { plugin.run_on_modifications(['clean.html.slim']) }
      end
    end

    it 'reports offences in a failing template' do
      in_slim_project do
        expect(Guard::UI).to receive(:info).with('Slim offences have been detected'.red)
        catch(:task_has_failed) { plugin.run_on_modifications(['failing.html.slim']) }
      end
    end

    # Regression test for the bug where paths were interpolated into a shell
    # string, so "sp ace/x.slim" reached slim-lint as two arguments.
    it 'lints a path containing a space' do
      in_slim_project do |dir|
        FileUtils.mkdir(File.join(dir, 'sp ace'))
        FileUtils.cp('clean.html.slim', File.join(dir, 'sp ace', 'clean.html.slim'))

        expect(Guard::UI).to receive(:info).with('No Slim offences detected'.green)
        catch(:task_has_failed) { plugin.run_on_modifications(['sp ace/clean.html.slim']) }
      end
    end

    it 'handles several paths at once' do
      in_slim_project do
        expect(Guard::UI).to receive(:info).with('Slim offences have been detected'.red)
        catch(:task_has_failed) do
          plugin.run_on_modifications(['clean.html.slim', 'failing.html.slim'])
        end
      end
    end

    it 'lints additions the same way as modifications' do
      in_slim_project do
        expect(Guard::UI).to receive(:info).with('No Slim offences detected'.green)
        catch(:task_has_failed) { plugin.run_on_additions(['clean.html.slim']) }
      end
    end

    it 'lints the whole project on run_all' do
      in_slim_project do
        expect(Guard::UI).to receive(:info).with('Slim offences have been detected'.red)
        catch(:task_has_failed) { plugin.run_all }
      end
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

  describe 'notification options' do
    {
      none: { success: false, failure: false },
      both: { success: true, failure: true },
      failure: { success: false, failure: true },
      success: { success: true, failure: false }
    }.each do |option, expectations|
      context "when :notify_on is #{option.inspect}" do
        subject(:plugin) { described_class.new(notify_on: option) }

        it "#{expectations[:success] ? 'notifies' : 'stays quiet'} when no offences are found" do
          expect(plugin.send(:notification_allowed?, true)).to eq(expectations[:success])
        end

        it "#{expectations[:failure] ? 'notifies' : 'stays quiet'} when offences are found" do
          expect(plugin.send(:notification_allowed?, false)).to eq(expectations[:failure])
        end
      end
    end

    it 'defaults to notifying on failure only' do
      expect(described_class.new.notify_on).to eq(:failure)
    end

    it 'sends the slim-lint error message to the notifier' do
      plugin = described_class.new(notify_on: :both)
      allow(Guard::UI).to receive(:error)
      expect(Guard::Notifier).to receive(:notify)
        .with('slim-lint exited with status 70', title: 'Slim-lint results', image: :failed)

      allow(plugin).to receive(:lint).and_return(70)
      catch(:task_has_failed) { plugin.run_on_modifications(['a.html.slim']) }
    end
  end
end
