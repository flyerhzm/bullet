require 'spec_helper'

describe Bullet::Detector::Counter do
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

describe Bullet::Detector::Counter do
  it "should not need counter cache" do
    Person.all.each do |person|
      person.pets.size
    end
    Bullet.collected_counter_cache_notifications.should be_empty
  end
end
