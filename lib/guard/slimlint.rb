# frozen_string_literal: true

require 'English'
require 'guard/compat/plugin'
require 'colorize'

module Guard
  class SlimLint < Plugin
    # slim-lint reports its outcome with sysexits(3) codes. Only EX_DATAERR
    # means "the linter ran and found offences"; every other non-zero status is
    # slim-lint itself failing, and must not be reported as a lint failure.
    EXIT_SUCCESS = 0
    EXIT_LINT_FAILURE = 65

    attr_accessor :notify_on, :all_on_start

    def initialize(options = {})
      @notify_on    = options.fetch(:notify_on, :failure)
      @all_on_start = options.fetch(:all_on_start, true)
      super
    end

    def start
      run_all if all_on_start
    end

    def run_all
      run
    end

    def run_on_modifications(paths)
      run(paths)
    end

    def run_on_additions(paths)
      run(paths)
    end

    private

    def run(paths = ['.'])
      status = lint(paths)

      case status
      when EXIT_SUCCESS then report_success
      when EXIT_LINT_FAILURE then report_offences
      else report_error(status)
      end
    end

    # Runs slim-lint without a shell, so paths containing spaces or shell
    # metacharacters reach the linter untouched.
    #
    # @param paths [Array<String>]
    # @return [Integer, nil] the exit status, or nil if slim-lint never ran
    def lint(paths)
      system('slim-lint', *paths)
      $CHILD_STATUS&.exitstatus
    end

    def report_success
      UI.info 'No Slim offences detected'.green
      check_and_notify(true)
    end

    def report_offences
      UI.info 'Slim offences have been detected'.red
      check_and_notify(false)
      throw :task_has_failed
    end

    def report_error(status)
      message = error_message(status)
      UI.error message
      check_and_notify(false, message)
      throw :task_has_failed
    end

    def error_message(status)
      return 'slim-lint could not be run' if status.nil?

      "slim-lint exited with status #{status}"
    end

    def notification_allowed?(result)
      case notify_on
      when :failure then !result
      when :success then result
      when :both then true
      else false
      end
    end

    def check_and_notify(result, message = default_message(result))
      notify(result, message) if notification_allowed?(result)
    end

    def image(result)
      result ? :success : :failed
    end

    def default_message(result)
      result ? 'No slim offences' : 'Slim offences detected'
    end

    def notify(result, message = default_message(result))
      Notifier.notify(message, title: 'Slim-lint results', image: image(result))
    end
  end
end
