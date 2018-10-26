# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/uberspace/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Jan Schulz-Hofen", "Martin Meyerhoff"]
  gem.license       = 'MIT'
  gem.email         = ["mamhoff@gmail.com"]
  gem.description   = %q{Capistrano 3 tasks to deploy to Uberspace 7}
  gem.summary       = %q{Capistrano::Uberspace helps you deploy a Ruby on Rails app on Uberspace, a popular German shared hosting provider.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capistrano-uberspace"
  gem.require_paths = ["lib"]
  gem.version       = Capistrano::Uberspace::VERSION

  # dependencies for capistrano
  gem.add_dependency 'capistrano', '~> 3.1'
end
