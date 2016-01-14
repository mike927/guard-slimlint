require 'guard/plugin'
require 'colorize'

module Guard
  module SlimLint
    class SlimLint < Plugin
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

      def run(paths = [])
        UI.info "Inspecting Slim code style: #{paths.join(' ')}"
        if system "bundle exec slim-lint #{paths.join(' ')}"
          UI.info "No Slim offences detected".green
        else
          UI.info "There are Slim offences ^^^".red
          Notifier.notify('Some offences are found', title: 'slim-lint results', image: :failed)
        end
      end
    end
  end
end
