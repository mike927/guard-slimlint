require 'guard/compat/plugin'
require 'colorize'
require 'guard/slimlint/notifier'

module Guard
  class SlimLint < Plugin
    def initialize(options = {})
      super
    end

    def run_all
      run
    end

    def start
      run
    end

    def run_on_modifications(path)
      run(path)
    end

    def run_on_additions(path)
      run(path)
    end

    private

    def run(path = ['.'])
      if system("slim-lint #{path.join(" ")}")
        UI.info 'No Slim offences detected'.green
      else
        UI.info 'Slim offences has been detected'.red
        Notifier.notify(false, 'Slim offences detected')
      end
    end
  end
end
