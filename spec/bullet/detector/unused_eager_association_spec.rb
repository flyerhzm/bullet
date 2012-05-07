require 'spec_helper'

module Bullet
  module Detector
    describe UnusedEagerAssociation do
      before(:all) { @post = Post.first }
      before(:each) { UnusedEagerAssociation.clear }

      context ".call_associations" do
        it "should get empty array if eager_loadgins" do
          UnusedEagerAssociation.send(:call_associations, @post.bullet_ar_key, Set.new([:association])).should be_empty
        end

        it "should get call associations if object and association are both in eager_loadings and call_object_associations" do
          UnusedEagerAssociation.add_eager_loadings([@post], :association)
          UnusedEagerAssociation.add_call_object_associations(@post, :association)
          UnusedEagerAssociation.send(:call_associations, @post.bullet_ar_key, Set.new([:association])).should == [:association]
        end

        it "should not get call associations if not exist in call_object_associations" do
          UnusedEagerAssociation.add_eager_loadings([@post], :association)
          UnusedEagerAssociation.send(:call_associations, @post.bullet_ar_key, Set.new([:association])).should be_empty
        end
      end

      context ".diff_object_associations" do
        it "should return associations not exist in call_association" do
          UnusedEagerAssociation.send(:diff_object_associations, @post.bullet_ar_key, Set.new([:association])).should == [:association]
        end

        it "should return empty if associations exist in call_association" do
          UnusedEagerAssociation.add_eager_loadings([@post], :association)
          UnusedEagerAssociation.add_call_object_associations(@post, :association)
          UnusedEagerAssociation.send(:diff_object_associations, @post.bullet_ar_key, Set.new([:association])).should be_empty
        end
      end

      context ".check_unused_preload_associations" do
        it "should set @@checked to true" do
          UnusedEagerAssociation.check_unused_preload_associations
          UnusedEagerAssociation.class_variable_get(:@@checked).should be_true
        end

        it "should create notification if object_association_diff is not empty" do
          UnusedEagerAssociation.add_object_associations(@post, :association)
          UnusedEagerAssociation.should_receive(:create_notification).with("Post", [:association])
          UnusedEagerAssociation.check_unused_preload_associations
        end

        it "should not create notification if object_association_diff is empty" do
          UnusedEagerAssociation.clear
          UnusedEagerAssociation.add_object_associations(@post, :association)
          UnusedEagerAssociation.add_eager_loadings([@post], :association)
          UnusedEagerAssociation.add_call_object_associations(@post, :association)
          UnusedEagerAssociation.send(:diff_object_associations, @post.bullet_ar_key, Set.new([:association])).should be_empty
          UnusedEagerAssociation.should_not_receive(:create_notification).with("Post", [:association])
          UnusedEagerAssociation.check_unused_preload_associations
        end
      end
    end
  end
end
