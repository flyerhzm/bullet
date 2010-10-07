lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "bullet/version"

Gem::Specification.new do |s|
  s.name        = "bullet"
  s.version     = Bullet::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Richard Huang"]
  s.email       = ["flyerhzm@gmail.com"]
  s.homepage    = "http://github.com/flyerhzm/bullet"
  s.summary     = "A rails plugin to kill N+1 queries and unused eager loading."
  s.description = "A rails plugin to kill N+1 queries and unused eager loading."

  s.required_rubygems_version = ">= 1.3.6"

  s.extra_rdoc_files = %w(MIT-LICENSE README.textile README_for_rails2.textile)
  s.files        = Dir.glob("lib/**/*") + %w(MIT-LICENSE README.textile README_for_rails2.textile)
  s.require_path = 'lib'
end

