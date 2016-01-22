require 'guard/compat/plugin'
require 'colorize'

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

    def run_on_modifications(paths)
      run(paths)
    end

    def run_on_additions(paths)
      run(paths)
    end

    private

    def run(paths = '.')
      UI.info "Inspecting Slim code style: #{paths}"
      if system "bundle exec slim-lint #{paths}"
        UI.info 'No Slim offences detected'.green
      else
        UI.info 'There are Slim offences ^^^'.red
        Notifier.notify('Slim offences detected', title: 'Slim-lint results', image: :failed)
      end
    end
  end
end
