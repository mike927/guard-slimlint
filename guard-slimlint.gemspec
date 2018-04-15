lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guard/slimlint/version'

Gem::Specification.new do |spec|
  spec.name          = 'guard-slimlint'
  spec.version       = Guard::SlimLintVersion::VERSION
  spec.authors       = ['Michal Gajowiak']
  spec.email         = ['michal.gajowiak.927@gmail.cok']

  spec.summary       = 'Guard::SlimLint runs slim-lint automatically'
  spec.homepage      = 'https://github.com/mike927/guard-slimlint'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16', '>= 1.16.1'
  spec.add_development_dependency 'rake', '~> 12.3', '>= 12.3.1'
  spec.add_development_dependency 'rspec', '~> 3.7'

  spec.add_runtime_dependency 'colorize', '~> 0.8.1'
  spec.add_runtime_dependency 'guard', '~> 2.14', '>= 2.14.2'
  spec.add_runtime_dependency 'guard-compat', '~> 1.2', '>= 1.2.1'
  spec.add_runtime_dependency 'slim_lint', '~> 0.15.1'
end
