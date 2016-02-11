# coding: utf-8

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'guard/compat/plugin'

RSpec.configure do |config|
  config.before do
    @core = File.expand_path('../../', __FILE__)
    @failfile = File.expand_path('../fixtures/failfile.html.slim', __FILE__)
    @testfile = File.expand_path('../fixtures/testfile.html.slim', __FILE__)
    @lib_guardfile = File.expand_path('lib/guard/slimlint/templates/Guardfile', @core)
    @core_guardfile = File.expand_path('Guardfile', @core)
  end
end
