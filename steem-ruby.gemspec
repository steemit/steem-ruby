# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'steem/version'

Gem::Specification.new do |spec|
  spec.name = 'steem-ruby'
  spec.version = Steem::VERSION
  spec.authors = ['Anthony Martin']
  spec.email = ['anthony@steem.com']

  spec.summary = %q{Steem Ruby Client}
  spec.description = %q{Client for accessing the Steem blockchain.}
  spec.homepage = 'https://github.com/steem/steem-ruby'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test)/}) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.1', '>= 1.16.1'
  spec.add_development_dependency 'rake', '~> 13.0', '>= 12.3.0'
  spec.add_development_dependency 'minitest', '~> 5.10', '>= 5.10.3'
  spec.add_development_dependency 'minitest-line', '~> 0.6', '>= 0.6.4'
  spec.add_development_dependency 'minitest-proveit', '~> 1.0', '>= 1.0.0'
  spec.add_development_dependency 'webmock', '~> 3.3', '>= 3.3.0'
  spec.add_development_dependency 'simplecov', '~> 0.15', '>= 0.15.1'
  spec.add_development_dependency 'vcr', '~> 6.0', '>= 4.0.0'
  spec.add_development_dependency 'yard', '~> 0.9', '>= 0.9.12'
  spec.add_development_dependency 'pry', '~> 0.11', '>= 0.11.3'
  spec.add_development_dependency 'awesome_print', '~> 1.8', '>= 1.8.0'
  spec.add_development_dependency 'rb-readline', '~> 0.5', '>= 0.5.5'
  spec.add_development_dependency 'irb', '~> 1.0', '>= 1.0.0'
  spec.add_development_dependency 'highline', '~> 2.0', '>= 2.0.3'
  
  spec.add_dependency 'json', '~> 2.1', '>= 2.1.0'
  spec.add_dependency 'logging', '~> 2.2', '>= 2.2.0'
  spec.add_dependency 'hashie', '~> 4.1', '>= 3.5.7'
  spec.add_dependency 'bitcoin-ruby', '~> 0.0', '>= 0.0.18'
  spec.add_dependency 'ffi', '~> 1.9', '>= 1.9.23'
  spec.add_dependency 'bindata', '~> 2.4', '>= 2.4.4'
  spec.add_dependency 'base58', '~> 0.2', '>= 0.2.3'
end
