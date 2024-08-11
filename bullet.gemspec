# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
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
  s.metadata    = {
    'changelog_uri' => 'https://github.com/flyerhzm/bullet/blob/main/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/flyerhzm/bullet'
  }

  s.license = 'MIT'

  s.required_ruby_version = '>= 2.7.0'
  s.required_rubygems_version = '>= 1.3.6'

  s.add_runtime_dependency 'activesupport', '>= 3.0.0'
  s.add_runtime_dependency 'uniform_notifier', '~> 1.11'

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |file|
      file.start_with?(*%w[.git .rspec Gemfile Guardfile Hacking Rakefile
                           bullet.gemspec perf rails spec test.sh update.sh])
    end
  end
  s.require_paths = ['lib']
end
