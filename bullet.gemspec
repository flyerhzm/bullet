# frozen_string_literal: true

lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'bullet/version'

Gem::Specification.new do |s|
  s.name        = 'bullet'
  s.version     = Bullet::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Richard Huang']
  s.email       = ['flyerhzm@gmail.com']
  s.homepage    = 'https://github.com/flyerhzm/bullet'
  s.summary     = 'help to kill N+1 queries and unused eager loading.'
  s.description = 'help to kill N+1 queries and unused eager loading.'

  s.license     = 'MIT'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_runtime_dependency 'activesupport', '>= 3.0.0'
  s.add_runtime_dependency 'uniform_notifier', '~> 1.11.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ['lib']
end
