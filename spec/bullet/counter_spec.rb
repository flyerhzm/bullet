require File.dirname(__FILE__) + '/../spec_helper'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

describe Bullet::Counter do
  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :countries do |t|
        t.string :name
      end

      create_table :cities do |t|
        t.string :name
        t.integer :country_id
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class Country < ActiveRecord::Base
    has_many :cities
  end

  class City < ActiveRecord::Base
    belongs_to :country
  end

  before(:all) do
    setup_db

    country1 = Country.create(:name => 'first')
    country2 = Country.create(:name => 'second')
    
    country1.cities.create(:name => 'first')
    country1.cities.create(:name => 'second')
    country2.cities.create(:name => 'third')
    country2.cities.create(:name => 'fourth')
  end

  after(:all) do
    teardown_db
  end

  before(:each) do
    Bullet::Counter.start_request
  end
  
  after(:each) do
    Bullet::Counter.end_request
  end

  it "should need counter cache with all cities" do
    Country.all.each do |country|
      country.cities.size
    end
    Bullet::Counter.should be_need_counter_caches
  end
  
  it "should not need coounter cache with only one object" do
    Country.first.cities.size
    Bullet::Counter.should_not be_need_counter_caches
  end

  it "should not need counter cache with part of cities" do
    Country.all.each do |country|
      country.cities(:conditions => ["name = ?", 'first']).size
    end
    Bullet::Counter.should_not be_need_counter_caches
  end
end

describe Bullet::Counter do
  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
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

  class Person < ActiveRecord::Base
    has_many :pets
  end

  class Pet < ActiveRecord::Base
    belongs_to :person, :counter_cache => true
  end

  before(:all) do
    setup_db

    person1 = Person.create(:name => 'first')
    person2 = Person.create(:name => 'second')
    
    person1.pets.create(:name => 'first')
    person1.pets.create(:name => 'second')
    person2.pets.create(:name => 'third')
    person2.pets.create(:name => 'fourth')
  end

  after(:all) do
    teardown_db
  end

  before(:each) do
    Bullet::Counter.start_request
  end
  
  after(:each) do
    Bullet::Counter.end_request
  end

  it "should not need counter cache" do
    Person.all.each do |person|
      person.pets.size
    end
    Bullet::Counter.should_not be_need_counter_caches
  end
end
