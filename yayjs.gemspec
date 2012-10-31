# -*- encoding: utf-8 -*-
require File.expand_path('../lib/yayjs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sergey Gridassov"]
  gem.email         = ["grindars@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{Furnace-powered Ruby to JavaScript compiler}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "yayjs"
  gem.require_paths = ["lib"]
  gem.version       = YAYJS::VERSION

  # Due to possibility of YARV changes. Change at your own risk.
  gem.required_ruby_version = '= 1.9.3'

  gem.add_runtime_dependency "furnace", '= 0.3.0.beta1'
  gem.add_runtime_dependency "trollop"
end
