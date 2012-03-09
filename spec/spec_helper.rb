#require 'pry'
require 'rubygems'
require 'rspec'
require 'rspec/autorun'
require 'rails'
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
Dir[ File.join(MODELS, "*.rb") ].sort.each do |file|
  name = File.basename(file, ".rb")
  autoload name.camelize.to_sym, name
end

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :countries do |t|
      t.string :name
    end

    create_table :cities do |t|
      t.string :name
      t.integer :country_id
    end

    create_table :people do |t|
      t.string :name
      t.integer :pets_count
    end

    create_table :pets do |t|
      t.string :name
      t.integer :person_id
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')


RSpec.configure do |config|
  config.before(:all) do
    setup_db

    country1 = Country.create(:name => 'first')
    country2 = Country.create(:name => 'second')

    country1.cities.create(:name => 'first')
    country1.cities.create(:name => 'second')
    country2.cities.create(:name => 'third')
    country2.cities.create(:name => 'fourth')

    person1 = Person.create(:name => 'first')
    person2 = Person.create(:name => 'second')

    person1.pets.create(:name => 'first')
    person1.pets.create(:name => 'second')
    person2.pets.create(:name => 'third')
    person2.pets.create(:name => 'fourth')
  end

  config.after(:all) do
    teardown_db
  end

  config.before(:each) do
    Bullet.start_request
  end

  config.after(:each) do
    Bullet.end_request
  end
end

module Bullet
  def self.collected_notifications_of_class( notification_class )
    Bullet.notification_collector.collection.select do |notification|
      notification.is_a? notification_class
    end
  end

  def self.collected_counter_cache_notifications
    collected_notifications_of_class Bullet::Notification::CounterCache
  end

  def self.collected_n_plus_one_query_notifications
    collected_notifications_of_class Bullet::Notification::NPlusOneQuery
  end

  def self.collected_unused_eager_association_notifications
    collected_notifications_of_class Bullet::Notification::UnusedEagerLoading
  end
end

module Bullet
  module Detector
    class Association
      class <<self
        # returns true if all associations are preloaded
        def completely_preloading_associations?
          Bullet.collected_n_plus_one_query_notifications.empty?
        end

        def has_unused_preload_associations?
          Bullet.collected_unused_eager_association_notifications.present?
        end

        # returns true if a given object has a specific association
        def creating_object_association_for?(object, association)
          object_associations[object].present? && object_associations[object].include?(association)
        end

        # returns true if a given class includes the specific unpreloaded association
        def detecting_unpreloaded_association_for?(klass, association)
          for_class_and_assoc = Bullet.collected_n_plus_one_query_notifications.select do |notification|
            notification.base_class == klass and
            notification.associations.include?( association )
          end
          for_class_and_assoc.present?
        end

        # returns true if the given class includes the specific unused preloaded association
        def unused_preload_associations_for?(klass, association)
          for_class_and_assoc = Bullet.collected_unused_eager_association_notifications.select do |notification|
            notification.base_class == klass and
            notification.associations.include?( association )
          end
          for_class_and_assoc.present?
        end
      end
    end
  end
end

class AppDouble
  def call env
    env = @env
    [ status, headers, response ]
  end

  def status= status
    @status = status
  end

  def headers= headers
    @headers = headers
  end

  def headers
    @headers ||= {}
    @headers
  end

  def response= response
    @response = response
  end

  private
  def status
    @status || 200
  end

  def response
    @response || ResponseDouble.new
  end
end

class ResponseDouble
  def initialize actual_body = nil
    @actual_body = actual_body
  end

  def body
    @body ||= "Hello world!"
  end

  def body= body
    @body = body
  end

  def each
    yield body
  end

  def close
  end
end
