require 'spec_helper'

# This test is just used for http://github.com/flyerhzm/bullet/issues/#issue/14
describe Bullet::Detector::Association do
  before(:each) do
    Bullet.clear
    Bullet.start_request
  end

  after(:each) do
    Bullet.end_request
  end

  describe "for chris" do
    it "should detect unpreload association from deal to hotel" do
      Deal.all.each do |deal|
        deal.hotel.location.name
      end
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Deal, :hotel)
    end

    it "should detect unpreload association from hotel to location" do
      Deal.includes(:hotel).each do |deal|
        deal.hotel.location.name
      end
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Hotel, :location)
    end

    it "should not detect unpreload association" do
      Deal.includes({:hotel => :location}).each do |deal|
        deal.hotel.location.name
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
    end
  end
end
