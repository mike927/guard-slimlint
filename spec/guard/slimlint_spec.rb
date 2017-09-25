require 'spec_helper'
require 'guard/notifier'
require 'guard/compat/test/helper'
require 'guard/slimlint'
require 'colorize'

RSpec.describe Guard::SlimLint do
  before { File.delete("#{@core}/Guardfile") if File.exist?("#{@core}/Guardfile") }
  before { system('bundle exec guard init') }
  after { File.delete("#{@core}/Guardfile") if File.exist?("#{@core}/Guardfile") }

  describe 'initialization guard' do
    let(:core_guardfile_content) { File.read(@core_guardfile) }
    let(:lib_guardfile_content) { File.read(@lib_guardfile) }

    context 'when Guardfile does not exists' do
      it { expect(File.exist?("#{@core}/Guardfile")).to be true }
      it { expect(core_guardfile_content).to include(lib_guardfile_content) }
    end

    context 'when Guardfile already exists' do
      before { system('bundle exec guard init') }
      it { expect(core_guardfile_content).to include(lib_guardfile_content) }
    end
  end

  describe 'ui loggers' do
    subject { described_class.new(notify_on: :none) }

    context 'when some offences are found' do
      it do
        expect(Guard::UI).to receive(:info).with('Slim offences has been detected'.red)
        subject.run_on_modifications([@failfile])
      end
    end

    context 'when no offences found' do
      it do
        expect(Guard::UI).to receive(:info).with('No Slim offences detected'.green)
        subject.run_on_modifications([@testfile])
      end
    end
  end

  describe '#start' do
    context 'when :all_on_start option is enabled' do
      subject { described_class.new(all_on_start: true) }

      it 'runs all' do
        expect(subject).to receive(:run_all)
        subject.start
      end
    end

    context 'when :all_on_start option is disabled' do
      subject { described_class.new(all_on_start: false) }

      it 'does nothing' do
        expect(subject).not_to receive(:run_all)
        subject.start
      end
    end
  end

  describe 'notifiers' do
    context 'when option set on :none' do
      subject { described_class.new(notify_on: :none) }

      context 'when some offences detected' do
        let(:result) { false }

        it { expect(subject.send(:notification_allowed?, result)).to eq(false) }
        it do
          expect(subject).not_to receive(:notify)
          subject.send(:check_and_notify, result)
        end
      end

      context 'when no offences detected' do
        let(:result) { true }

        it { expect(subject.send(:notification_allowed?, result)).to eq(false) }
        it do
          expect(subject).not_to receive(:notify)
          subject.send(:check_and_notify, result)
        end
      end
    end

    context 'when option set on :both' do
      subject { described_class.new(notify_on: :both) }

      context 'when some offences detected' do
        let(:result) { false }
        it { expect(subject.send(:notification_allowed?, result)).to eq(true) }
        it do
          expect(subject).to receive(:notify)
          subject.send(:check_and_notify, result)
        end
      end

      context 'when no offences detected' do
        let(:result) { true }

        it { expect(subject.send(:notification_allowed?, result)).to eq(true) }
        it do
          expect(subject).to receive(:notify)
          subject.send(:check_and_notify, result)
        end
      end
    end
  end

  context 'when option set on :failure' do
    subject { described_class.new(notify_on: :failure) }

    context 'when some offences detected' do
      let(:result) { false }
      it { expect(subject.send(:notification_allowed?, result)).to eq(true) }
      it do
        expect(subject).to receive(:notify)
        subject.send(:check_and_notify, result)
      end
    end

    context 'when no offences detected' do
      let(:result) { true }

      it { expect(subject.send(:notification_allowed?, result)).to eq(false) }
      it do
        expect(subject).not_to receive(:notify)
        subject.send(:check_and_notify, result)
      end
    end
  end

  context 'when option set on :success' do
    subject { described_class.new(notify_on: :success) }

    context 'when some offences detected' do
      let(:result) { false }
      it { expect(subject.send(:notification_allowed?, result)).to eq(false) }
      it do
        expect(subject).not_to receive(:notify)
        subject.send(:check_and_notify, result)
      end
    end

    context 'when no offences detected' do
      let(:result) { true }

      it { expect(subject.send(:notification_allowed?, result)).to eq(true) }
      it do
        expect(subject).to receive(:notify)
        subject.send(:check_and_notify, result)
      end
    end
  end

  context 'when no option set' do
    subject { described_class.new }
    it { expect(subject.notify_on).to eq(:failure) }
  end
end
