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

  context "category => posts, category => entries" do
    it "should detect non preload with category => [posts, entries]" do
      Mongoid::Category.all.each do |category|
        category.posts.map(&:name)
        category.entries.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Mongoid::Category, :posts)
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Mongoid::Category, :entries)
    end

    it "should detect preload with category => posts, but not with category => entries" do
      Mongoid::Category.includes(:posts).each do |category|
        category.posts.collect(&:name)
        category.entries.collect(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should_not be_detecting_unpreloaded_association_for(Mongoid::Category, :posts)
      Bullet::Detector::Association.should be_detecting_unpreloaded_association_for(Mongoid::Category, :entries)
    end

    it "should detect preload with category => [posts, entries]" do
      Mongoid::Category.includes([:posts, :entries]).each do |category|
        category.posts.map(&:name)
        category.entries.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_has_unused_preload_associations

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused with category => [posts, entries]" do
      Mongoid::Category.includes([:posts, :entries]).map(&:name)
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should be_unused_preload_associations_for(Mongoid::Category, :posts)
      Bullet::Detector::Association.should be_unused_preload_associations_for(Mongoid::Category, :entries)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

    it "should detect unused preload with category => entries, but not with category => posts" do
      Mongoid::Category.includes([:posts, :entries]).each do |category|
        category.posts.map(&:name)
      end
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      Bullet::Detector::Association.should_not be_unused_preload_associations_for(Mongoid::Category, :posts)
      Bullet::Detector::Association.should be_unused_preload_associations_for(Mongoid::Category, :entries)

      Bullet::Detector::Association.should be_completely_preloading_associations
    end

  end
end
