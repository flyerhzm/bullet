require 'spec_helper'

if active_record2?
  describe Bullet::Detector::Counter do
    before(:each) do
      Bullet.start_request
    end

    after(:each) do
      Bullet.end_request
    end

    it "should need counter cache with all cities" do
      Country.all.each do |country|
        country.cities.size
      end
      Bullet.collected_counter_cache_notifications.should_not be_empty
    end

    it "should not need counter cache if already define counter_cache" do
      Person.all.each do |person|
        person.pets.size
      end
      Bullet.collected_counter_cache_notifications.should be_empty
    end

    it "should not need counter cache with only one object" do
      Country.first.cities.size
      Bullet.collected_counter_cache_notifications.should be_empty
    end

    it "should not need counter cache with part of cities" do
      Country.all.each do |country|
        country.cities.find(:all, :conditions => {:name => 'first'}).size
      end
      Bullet.collected_counter_cache_notifications.should be_empty
    end
  end
end
