require 'guard/compat/plugin'
require 'colorize'

module Guard
  class SlimLint < Plugin
    attr_accessor :notify_on

    def initialize(options = {})
      @notify_on = options[:notify_on] ? options[:notify_on] : :failure
      super
    end

    def start
      run
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
      result = system "slim-lint #{paths.join(' ')}"
      if result
        UI.info 'No Slim offences detected'.green
      else
        UI.info 'Slim offences has been detected'.red
      end
      check_and_notify(result)
    end

    def notification_allowed?(result)
      case notify_on
      when :failure then !result
      when :success then result
      when :both then true
      when :none then false
      end
    end

    def check_and_notify(result)
      notify(result) if notification_allowed?(result)
    end

    def image(result)
      result ? :success : :failed
    end

    def message(result)
      result ? 'No slim offences' : 'Slim offences detected'
    end

    def notify(result)
      Notifier.notify(message(result), title: 'Slim-lint results', image: image(result))
    end
  end
end
