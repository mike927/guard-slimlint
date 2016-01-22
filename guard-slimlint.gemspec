# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guard/slimlint/version'

Gem::Specification.new do |spec|
  spec.name          = 'guard-slimlint'
  spec.version       = Guard::SlimLintVersion::VERSION
  spec.authors       = ['Michal Gajowiak']
  spec.email         = ['michal.gajowiak@softiti.com']

  spec.summary       = 'Guard::SlimLint runs slim-lint automatically'
  spec.homepage      = 'https://github.com/mike927/guard-slimlint'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_runtime_dependency 'guard'
  spec.add_runtime_dependency 'guard-compat'
  spec.add_runtime_dependency 'slim_lint'
  spec.add_runtime_dependency 'colorize'
end
