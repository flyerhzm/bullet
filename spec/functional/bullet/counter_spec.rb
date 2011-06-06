require 'spec_helper'

describe Bullet::Detector::Counter do
  before :each do
    Bullet.start_request
  end

  after :each do
    Bullet.end_request
  end

  context "non counter_cache" do
    before :all do
      country1 = Country.create(:name => 'first')
      country2 = Country.create(:name => 'second')

      country1.cities.create(:name => 'first')
      country1.cities.create(:name => 'second')
      country2.cities.create(:name => 'third')
      country2.cities.create(:name => 'fourth')
    end

    it "should need counter cache with all cities" do
      Country.all.each do |country|
        country.cities.size
      end
      Bullet.collected_counter_cache_notifications.should_not be_empty
    end

    it "should not need coounter cache with only one object" do
      Country.first.cities.size
      Bullet.collected_counter_cache_notifications.should be_empty
    end

    it "should not need counter cache with part of cities" do
      Country.all.each do |country|
        country.cities.where(:name => 'first').size
      end
      Bullet.collected_counter_cache_notifications.should be_empty
    end
  end

  context "exist counter_cache" do
    before :all do
      user1 = User.create(:name => 'first')
      user2 = User.create(:name => 'second')

      user1.pets.create(:name => 'first')
      user1.pets.create(:name => 'second')
      user2.pets.create(:name => 'third')
      user2.pets.create(:name => 'fourth')
    end

    it "should not need counter cache" do
      User.all.each do |user|
        user.pets.size
      end
      Bullet.collected_counter_cache_notifications.should be_empty
    end
  end
end
