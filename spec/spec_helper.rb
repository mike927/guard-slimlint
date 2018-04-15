$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'guard/compat/plugin'

RSpec.configure do |config|
  config.before do
    @core = File.expand_path('..', __dir__)
    @failfile = File.expand_path('fixtures/failfile.html.slim', __dir__)
    @testfile = File.expand_path('fixtures/testfile.html.slim', __dir__)
    @lib_guardfile = File.expand_path('lib/guard/slimlint/templates/Guardfile', @core)
    @core_guardfile = File.expand_path('Guardfile', @core)
  end
end
