source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gemspec

gem 'activerecord-import'
gem 'activerecord-jdbcsqlite3-adapter', platforms: [:jruby]
gem 'rails', github: 'rails'
gem 'sqlite3', platforms: [:ruby]

gem 'guard'
gem 'guard-rspec'
gem 'rspec'

gem 'coveralls', require: false

platforms :rbx do
  gem 'rubinius-developer_tools'
  gem 'rubysl', '~> 2.0'
end
