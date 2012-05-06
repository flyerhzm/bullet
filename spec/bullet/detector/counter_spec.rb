require 'spec_helper'

module Bullet
  module Detector
    describe Counter do
      before :all do
        @post1 = Post.first
        @post2 = Post.last
      end
      before(:each) { Counter.clear }

      context ".clear" do
        it "should clear all class variables" do
          Counter.class_variable_get(:@@possible_objects).should be_nil
          Counter.class_variable_get(:@@impossible_objects).should be_nil
        end
      end

      context ".add_counter_cache" do
        it "should create notification if conditions met" do
          Counter.should_receive(:conditions_met?).with(@post1.bullet_ar_key, [:comments]).and_return(true)
          Counter.should_receive(:create_notification).with("Post", [:comments])
          Counter.add_counter_cache(@post1, [:comments])
        end

        it "should not create notification if conditions not met" do
          Counter.should_receive(:conditions_met?).with(@post1.bullet_ar_key, [:comments]).and_return(false)
          Counter.should_receive(:create_notification).never
          Counter.add_counter_cache(@post1, [:comments])
        end
      end

      context ".add_possible_objects" do
        it "should add possible objects" do
          Counter.add_possible_objects([@post1, @post2])
          Counter.send(:possible_objects).should be_include(@post1.bullet_ar_key)
          Counter.send(:possible_objects).should be_include(@post2.bullet_ar_key)
        end

        it "should add impossible object" do
          Counter.add_impossible_object(@post1)
          Counter.send(:impossible_objects).should be_include(@post1.bullet_ar_key)
        end
      end

      context ".conditions_met?" do
        it "should be true when object is possible, not impossible" do
          Counter.add_possible_objects(@post1)
          Counter.send(:conditions_met?, @post1.bullet_ar_key, :associations).should be_true
        end

        it "should be false when object is not possible" do
          Counter.send(:conditions_met?, @post1.bullet_ar_key, :associations).should be_false
        end

        it "should be true when object is possible, and impossible" do
          Counter.add_possible_objects(@post1)
          Counter.add_impossible_object(@post1)
          Counter.send(:conditions_met?, @post1.bullet_ar_key, :associations).should be_false
        end
      end
    end
  end
end
