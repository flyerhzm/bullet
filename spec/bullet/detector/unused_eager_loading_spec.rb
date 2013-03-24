require 'spec_helper'

module Bullet
  module Detector
    describe UnusedEagerLoading do
      before(:all) do
        @post = Post.first
        @post2 = Post.last
      end
      before(:each) { UnusedEagerLoading.clear }

      context ".call_associations" do
        it "should get empty array if eager_loadgins" do
          UnusedEagerLoading.send(:call_associations, @post.bullet_ar_key, Set.new([:association])).should be_empty
        end

        it "should get call associations if object and association are both in eager_loadings and call_object_associations" do
          UnusedEagerLoading.add_eager_loadings([@post], :association)
          UnusedEagerLoading.add_call_object_associations(@post, :association)
          UnusedEagerLoading.send(:call_associations, @post.bullet_ar_key, Set.new([:association])).should == [:association]
        end

        it "should not get call associations if not exist in call_object_associations" do
          UnusedEagerLoading.add_eager_loadings([@post], :association)
          UnusedEagerLoading.send(:call_associations, @post.bullet_ar_key, Set.new([:association])).should be_empty
        end
      end

      context ".diff_object_associations" do
        it "should return associations not exist in call_association" do
          UnusedEagerLoading.send(:diff_object_associations, @post.bullet_ar_key, Set.new([:association])).should == [:association]
        end

        it "should return empty if associations exist in call_association" do
          UnusedEagerLoading.add_eager_loadings([@post], :association)
          UnusedEagerLoading.add_call_object_associations(@post, :association)
          UnusedEagerLoading.send(:diff_object_associations, @post.bullet_ar_key, Set.new([:association])).should be_empty
        end
      end

      context ".check_unused_preload_associations" do
        it "should set @@checked to true" do
          UnusedEagerLoading.check_unused_preload_associations
          UnusedEagerLoading.class_variable_get(:@@checked).should be_true
        end

        it "should create notification if object_association_diff is not empty" do
          UnusedEagerLoading.add_object_associations(@post, :association)
          UnusedEagerLoading.should_receive(:create_notification).with("Post", [:association])
          UnusedEagerLoading.check_unused_preload_associations
        end

        it "should not create notification if object_association_diff is empty" do
          UnusedEagerLoading.clear
          UnusedEagerLoading.add_object_associations(@post, :association)
          UnusedEagerLoading.add_eager_loadings([@post], :association)
          UnusedEagerLoading.add_call_object_associations(@post, :association)
          UnusedEagerLoading.send(:diff_object_associations, @post.bullet_ar_key, Set.new([:association])).should be_empty
          UnusedEagerLoading.should_not_receive(:create_notification).with("Post", [:association])
          UnusedEagerLoading.check_unused_preload_associations
        end
      end

      context ".add_eager_loadings" do
        it "should add objects, associations pair when eager_loadings are empty" do
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :associations)
          UnusedEagerLoading.send(:eager_loadings).should be_include([@post.bullet_ar_key, @post2.bullet_ar_key], :associations)
        end

        it "should add objects, associations pair for existing eager_loadings" do
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :association1)
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :association2)
          UnusedEagerLoading.send(:eager_loadings).should be_include([@post.bullet_ar_key, @post2.bullet_ar_key], :association1)
          UnusedEagerLoading.send(:eager_loadings).should be_include([@post.bullet_ar_key, @post2.bullet_ar_key], :association2)
        end

        it "should merge objects, associations pair for existing eager_loadings" do
          UnusedEagerLoading.add_eager_loadings([@post], :association1)
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :association2)
          UnusedEagerLoading.send(:eager_loadings).should be_include([@post.bullet_ar_key], :association1)
          UnusedEagerLoading.send(:eager_loadings).should be_include([@post.bullet_ar_key], :association2)
          UnusedEagerLoading.send(:eager_loadings).should be_include([@post.bullet_ar_key, @post2.bullet_ar_key], :association2)
        end

        it "should delete objects, associations pair for existing eager_loadings" do
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :association1)
          UnusedEagerLoading.add_eager_loadings([@post], :association2)
          UnusedEagerLoading.send(:eager_loadings).should be_include([@post.bullet_ar_key], :association1)
          UnusedEagerLoading.send(:eager_loadings).should be_include([@post.bullet_ar_key], :association2)
          UnusedEagerLoading.send(:eager_loadings).should be_include([@post2.bullet_ar_key], :association1)
        end
      end
    end
  end
end
