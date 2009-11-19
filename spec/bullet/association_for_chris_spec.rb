require File.dirname(__FILE__) + '/../spec_helper'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
# This test is just used for http://github.com/flyerhzm/bullet/issues/#issue/14
describe Bullet::Association, 'for chris' do

  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :locations do |t|
        t.column :name, :string
      end

      create_table :hotels do |t|
        t.column :name, :string
        t.column :location_id, :integer
      end

      create_table :deals do |t|
        t.column :name, :string
        t.column :hotel_id, :integer
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class Location < ActiveRecord::Base
    has_many :hotels
  end
  
  class Hotel < ActiveRecord::Base
    belongs_to :location
    has_many :deals
  end
  
  class Deal < ActiveRecord::Base
    belongs_to :hotel
    has_one :location, :through => :hotel
  end

  before(:all) do
    setup_db
    
    location1 = Location.create(:name => "location1")
    location2 = Location.create(:name => "location2")
    
    hotel1 = location1.hotels.create(:name => "hotel1")
    hotel2 = location1.hotels.create(:name => "hotel2")
    hotel3 = location2.hotels.create(:name => "hotel3")
    hotel4 = location2.hotels.create(:name => "hotel4")
    
    deal1 = hotel1.deals.create(:name => "deal1")
    deal2 = hotel2.deals.create(:name => "deal2")
    deal3 = hotel3.deals.create(:name => "deal3")
    deal4 = hotel4.deals.create(:name => "deal4")
  end

  after(:all) do
    teardown_db
  end

  before(:each) do
    Bullet::Association.start_request
  end

  after(:each) do
    Bullet::Association.end_request
  end
  
  it "should detect unpreload association from deal to hotel" do
    Deal.find(:all).each do |deal|
      deal.hotel.location.name
    end
    Bullet::Association.should be_detecting_unpreloaded_association_for(Deal, :hotel)
  end
  
  it "should detect unpreload association from hotel to location" do
    Deal.find(:all, :include => :hotel).each do |deal|
      deal.hotel.location.name
    end
    Bullet::Association.should be_detecting_unpreloaded_association_for(Hotel, :location)
  end
  
  it "should not detect unpreload association" do
    Deal.find(:all, :include => {:hotel => :location}).each do |deal|
      deal.hotel.location.name
    end
    Bullet::Association.should_not be_has_unused_preload_associations
  end
end