require 'rspec'
begin
  require 'rails'
rescue LoadError
  # rails 2.3
  require 'initializer'
end
require 'active_record'
require 'action_controller'

module Rails
  class <<self
    def root
      File.expand_path(__FILE__).split('/')[0..-3].join('/')
    end
  end
end

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
require 'bullet'
Bullet.enable = true
ActiveRecord::Migration.verbose = false

MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)

# Autoload every model for the test suite that sits in spec/models.
Dir[ File.join(MODELS, "*.rb") ].sort.each do |filename|
  name = File.basename(filename, ".rb")
  autoload name.camelize.to_sym, name
end

SUPPORT = File.join(File.dirname(__FILE__), "support")
Dir[ File.join(SUPPORT, "*.rb") ].reject { |filename| filename =~ /mongo_seed.rb$/ }.sort.each { |file| require file }

RSpec.configure do |config|
  config.before(:suite) do
    Support::SqliteSeed.setup_db
    Support::SqliteSeed.seed_db
  end

  config.after(:suite) do
    Support::SqliteSeed.teardown_db
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

begin
  require 'mongoid'

  # Autoload every model for the test suite that sits in spec/models.
  Dir[ File.join(MODELS, "mongoid", "*.rb") ].sort.each { |file| require file }
  require File.join(SUPPORT, "mongo_seed.rb")

  RSpec.configure do |config|
    config.before(:suite) do
      Support::MongoSeed.setup_db
      Support::MongoSeed.seed_db
    end

    config.after(:suite) do
      Support::MongoSeed.teardown_db
    end
  end
rescue LoadError
end
