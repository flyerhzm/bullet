require 'spec_helper'

describe Bullet::Detector::Association, 'has_many' do
  before(:each) { Bullet.start_request }
  after(:each) { Bullet.end_request }

  context "category => posts => comments" do
    it "should detect non preload category => posts => comments" do
      Mongoid::Category.all.each do |category|
        category.posts.each do |post|
          post.comments.map(&:name)
        end
      end
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Mongoid::Category, :posts)
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Mongoid::Post, :comments)
    end

    it "should detect preload category => posts, but not detect post => comments" do
      Mongoid::Category.includes(:posts).each do |category|
        category.posts.each do |post|
          post.comments.map(&:name)
        end
      end
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
      Bullet::Detector::Association.should_not be_detecting_unpreloaded_association_for(Mongoid::Category, :posts)
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Mongoid::Post, :comments)
    end

    it "should getect preoad with category => posts => comments" do
      Mongoid::Category.includes({:posts => :comments}).each do |category|
        category.posts.each do |post|
          post.comments.map(&:name)
        end
      end
      Bullet::Detector::Association.should_not be_has_unused_preload_associations
      Bullet::Detector::Association.should be_completely_preloading_associations
    end
  end
end
