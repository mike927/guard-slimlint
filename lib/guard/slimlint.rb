# frozen_string_literal: true

require 'English'
require 'shellwords'
require 'guard/compat/plugin'

module Guard
  class SlimLint < Plugin
    # slim-lint reports its outcome with sysexits(3) codes. Only EX_DATAERR
    # means "the linter ran and found offences"; every other non-zero status is
    # slim-lint itself failing, and must not be reported as a lint failure.
    EXIT_SUCCESS = 0
    EXIT_LINT_FAILURE = 65

    # Recognised :notify_on values. :change notifies only when the outcome
    # flips, which is what stops a long editing session from producing one
    # notification per save.
    NOTIFY_MODES = %i[change failure success both none].freeze

    # Statuses that are not slim-lint's own sysexits codes, paired with what a
    # user is most likely looking at. Bundler exits 1 when it cannot load the
    # command, and a shell exits 127 when the binary is missing; neither says
    # anything about Slim, so the bare number sends people hunting for lint
    # errors that do not exist.
    STATUS_HINTS = {
      1 => 'the bundle is probably out of sync, try bundle install',
      127 => 'slim-lint is not on PATH, check that the gem is installed'
    }.freeze

    attr_reader :notify_on, :all_on_start, :halt_on_fail, :cli

    def initialize(options = {})
      @notify_on    = options.fetch(:notify_on, :change)
      @all_on_start = options.fetch(:all_on_start, true)
      @halt_on_fail = options.fetch(:halt_on_fail, true)
      @cli          = options[:cli]
      # Assume the project starts green, so a clean first run stays quiet
      # under :change instead of announcing that nothing is wrong.
      @last_success = true

      validate_notify_on!
      super
    end

    def start
      run_all if all_on_start
    end

    def run_all
      run(lint_targets)
    end

    def run_on_modifications(paths)
      run(paths)
    end

    def run_on_additions(paths)
      run(paths)
    end

    private

    def validate_notify_on!
      return if NOTIFY_MODES.include?(notify_on)

      raise ArgumentError,
            "unknown :notify_on #{notify_on.inspect}, expected one of " \
            "#{NOTIFY_MODES.map(&:inspect).join(', ')}"
    end

    # The directories Guard was told to watch, so run_all honours a
    # `directories` line in the Guardfile instead of always sweeping the
    # whole project.
    def lint_targets
      dirs = Compat.watched_directories.map(&:to_s)
      dirs.empty? ? ['.'] : dirs
    rescue NotImplementedError
      # guard-compat raises this when Guard's CLI is not loaded, which
      # happens when the plugin is driven programmatically rather than by
      # `guard`. Linting the whole project is what run_all did before 2.0.0.
      ['.']
    end

    def run(paths)
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
      system('slim-lint', *cli_args, *paths)
      $CHILD_STATUS&.exitstatus
    end

    def cli_args
      case cli
      when Array then cli.map(&:to_s)
      when String then cli.shellsplit
      else []
      end
    end

    def report_success
      Compat::UI.info(Compat::UI.color('No Slim offences detected', :green))
      finish(true, 'No slim offences')
    end

    def report_offences
      Compat::UI.info(Compat::UI.color('Slim offences have been detected', :red))
      finish(false, 'Slim offences detected')
    end

    def report_error(status)
      message = error_message(status)
      Compat::UI.error(message)
      finish(false, message)
    end

    def error_message(status)
      return 'slim-lint could not be run' if status.nil?

      message = "slim-lint exited with status #{status}"
      hint = STATUS_HINTS[status]
      hint ? "#{message}: #{hint}" : message
    end

    # Notifies if the configured mode calls for it, records the outcome so
    # :change can compare against it next time, then hands back to Guard.
    def finish(success, message)
      notify(success, message) if notification_allowed?(success)
      @last_success = success
      throw :task_has_failed if halt_on_fail && !success
    end

    def notification_allowed?(success)
      case notify_on
      when :change then success != @last_success
      when :failure then !success
      when :success then success
      when :both then true
      else false
      end
    end

    def notify(success, message)
      Compat::UI.notify(message, title: 'Slim-lint results', image: success ? :success : :failed)
    end
  end
end
