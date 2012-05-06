require 'spec_helper'

describe Bullet::Detector::Association, 'has_many' do
  before(:each) do
    Bullet.clear
    Bullet.start_request
  end
  after(:each) do
    Bullet.end_request
  end

  context "posts => comments" do
    it "should detect non preload posts => comments" do
      Mongoid::Post.all.each do |post|
        post.comments.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Mongoid::Post, :comments)
    end

    it "should detect preload post => comments" do
      Mongoid::Post.includes(:comments).each do |post|
        post.comments.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload post => comments" do
      Mongoid::Post.includes(:comments).map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Mongoid::Post, :comments)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should not detect unused preload post => comments" do
      Mongoid::Post.all.map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end
end
