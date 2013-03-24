require 'spec_helper'

module Bullet
  module Detector
    describe CounterCache do
      before :all do
        @post1 = Post.first
        @post2 = Post.last
      end
      before(:each) { CounterCache.clear }

      context ".clear" do
        it "should clear all class variables" do
          CounterCache.class_variable_get(:@@possible_objects).should be_nil
          CounterCache.class_variable_get(:@@impossible_objects).should be_nil
        end
      end

      context ".add_counter_cache" do
        it "should create notification if conditions met" do
          CounterCache.should_receive(:conditions_met?).with(@post1.bullet_ar_key, [:comments]).and_return(true)
          CounterCache.should_receive(:create_notification).with("Post", [:comments])
          CounterCache.add_counter_cache(@post1, [:comments])
        end

        it "should not create notification if conditions not met" do
          CounterCache.should_receive(:conditions_met?).with(@post1.bullet_ar_key, [:comments]).and_return(false)
          CounterCache.should_receive(:create_notification).never
          CounterCache.add_counter_cache(@post1, [:comments])
        end
      end

      context ".add_possible_objects" do
        it "should add possible objects" do
          CounterCache.add_possible_objects([@post1, @post2])
          CounterCache.send(:possible_objects).should be_include(@post1.bullet_ar_key)
          CounterCache.send(:possible_objects).should be_include(@post2.bullet_ar_key)
        end

        it "should add impossible object" do
          CounterCache.add_impossible_object(@post1)
          CounterCache.send(:impossible_objects).should be_include(@post1.bullet_ar_key)
        end
      end

      context ".conditions_met?" do
        it "should be true when object is possible, not impossible" do
          CounterCache.add_possible_objects(@post1)
          CounterCache.send(:conditions_met?, @post1.bullet_ar_key, :associations).should be_true
        end

        it "should be false when object is not possible" do
          CounterCache.send(:conditions_met?, @post1.bullet_ar_key, :associations).should be_false
        end

        it "should be true when object is possible, and impossible" do
          CounterCache.add_possible_objects(@post1)
          CounterCache.add_impossible_object(@post1)
          CounterCache.send(:conditions_met?, @post1.bullet_ar_key, :associations).should be_false
        end
      end
    end
  end
end
