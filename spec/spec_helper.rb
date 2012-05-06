require 'rspec'
require 'rspec/autorun'
require 'rails'
require 'active_record'
require 'action_controller'
require 'mongoid'

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
Dir[ File.join(MODELS, "**/*.rb") ].sort.each do |file|
  require file
end

SUPPORT = File.join(File.dirname(__FILE__), "support")
Dir[ File.join(SUPPORT, "*.rb") ].sort.each { |file| require file }

RSpec.configure do |config|
  config.before(:suite) do
    Support::MongoSeed.setup_db
    Support::SqliteSeed.setup_db
    Support::MongoSeed.seed_db
    Support::SqliteSeed.seed_db
  end

  config.after(:suite) do
    Support::SqliteSeed.teardown_db
    Support::MongoSeed.teardown_db
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
