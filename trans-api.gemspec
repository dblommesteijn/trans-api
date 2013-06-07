# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trans-api/version'

Gem::Specification.new do |gem|
  gem.name          = "trans-api"
  gem.version       = Trans::Api::VERSION
  gem.authors       = ["Dennis Blommesteijn"]
  gem.email         = ["dennis@blommesteijn.com"]
  gem.description   = %q{Transmission RPC API for Ruby on Rails (gem).}
  gem.summary       = %q{Transmission RPC API for Ruby on Rails (gem)}
  gem.homepage      = ""

  # dependencies
  gem.add_dependency 'nokogiri'
  gem.add_dependency 'json'
  gem.add_development_dependency "test-unit"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
