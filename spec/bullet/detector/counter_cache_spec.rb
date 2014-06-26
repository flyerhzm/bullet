require 'spec_helper'

module Bullet
  module Detector
    describe CounterCache do
      before :all do
        @post1 = Post.first
        @post2 = Post.last
      end

      context ".add_counter_cache" do
        it "should create notification if conditions met" do
          expect(CounterCache).to receive(:conditions_met?).with(@post1.bullet_key, [:comments]).and_return(true)
          expect(CounterCache).to receive(:create_notification).with("Post", [:comments])
          CounterCache.add_counter_cache(@post1, [:comments])
        end

        it "should not create notification if conditions not met" do
          expect(CounterCache).to receive(:conditions_met?).with(@post1.bullet_key, [:comments]).and_return(false)
          expect(CounterCache).to receive(:create_notification).never
          CounterCache.add_counter_cache(@post1, [:comments])
        end
      end

      context ".add_possible_objects" do
        it "should add possible objects" do
          CounterCache.add_possible_objects([@post1, @post2])
          expect(CounterCache.send(:possible_objects)).to be_include(@post1.bullet_key)
          expect(CounterCache.send(:possible_objects)).to be_include(@post2.bullet_key)
        end

        it "should add impossible object" do
          CounterCache.add_impossible_object(@post1)
          expect(CounterCache.send(:impossible_objects)).to be_include(@post1.bullet_key)
        end
      end

      context ".conditions_met?" do
        it "should be true when object is possible, not impossible" do
          CounterCache.add_possible_objects(@post1)
          expect(CounterCache.send(:conditions_met?, @post1.bullet_key, :associations)).to eq true
        end

        it "should be false when object is not possible" do
          expect(CounterCache.send(:conditions_met?, @post1.bullet_key, :associations)).to eq false
        end

        it "should be true when object is possible, and impossible" do
          CounterCache.add_possible_objects(@post1)
          CounterCache.add_impossible_object(@post1)
          expect(CounterCache.send(:conditions_met?, @post1.bullet_key, :associations)).to eq false
        end
      end
    end
  end
end
