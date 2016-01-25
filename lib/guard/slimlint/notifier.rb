# encoding: utf-8

require 'guard/slimlint'

module Guard
  class SlimLint < Plugin
    class Notifier
      class << self
        def image(result)
          result ? :success : :failed
        end

        def notify(result, message)
          Compat::UI.notify(message, title: 'Slimlint results!', image: image(result))
        end
      end
    end
  end
end
