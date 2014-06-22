source 'https://rubygems.org'

gemspec

gem 'rails', github: 'rails/rails'
gem 'sqlite3', platforms: [:ruby]
gem 'activerecord-jdbcsqlite3-adapter', platforms: [:jruby]
gem 'activerecord-import'

gem 'rspec'
gem 'guard'
gem 'guard-rspec'

gem 'coveralls', require: false

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius-developer_tools'
end
