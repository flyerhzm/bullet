require 'spec_helper'

if active_record3? || active_record4?
  describe Bullet::Detector::CounterCache do
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
        country.cities.where(:name => 'first').size
      end
      Bullet.collected_counter_cache_notifications.should be_empty
    end

    context "disable" do
      before { Bullet.counter_cache_enable = false }
      after { Bullet.counter_cache_enable = true }

      it "should not detect counter cache" do
        Country.all.each do |country|
          country.cities.size
        end
        expect(Bullet.collected_counter_cache_notifications).to be_empty
      end
    end

    context "whitelist" do
      before { Bullet.add_whitelist :type => :counter_cache, :class_name => "Country", :association => :cities }
      after { Bullet.reset_whitelist }

      it "should not detect counter cache" do
        Country.all.each do |country|
          country.cities.size
        end
        expect(Bullet.collected_counter_cache_notifications).to be_empty
      end
    end
  end
end
