require 'spec_helper'

module Bullet
  module Detector
    describe Counter do
      after(:each) { Counter.clear }

      context ".clear" do
        it "should clear all class variables" do
          Counter.clear
          Counter.class_variable_get(:@@possible_objects).should be_nil
          Counter.class_variable_get(:@@impossible_objects).should be_nil
        end
      end

      context ".add_possible_objects" do
        it "should add possible objects" do
          object1 = Object.new
          object2 = Object.new
          Counter.add_possible_objects([object1, object2])
          Counter.send(:possible_objects).should be_include(object1)
          Counter.send(:possible_objects).should be_include(object2)
        end

        it "should add impossible object" do
          object = Object.new
          Counter.add_impossible_object(object)
          Counter.send(:impossible_objects).should be_include(object)
        end
      end

      context ".conditions_met?" do
        it "should be true when object is possible, not impossible" do
          object = Object.new
          Counter.add_possible_objects(object)
          Counter.send(:conditions_met?, object, :associations).should be_true
        end

        it "should be false when object is not possible" do
          object = Object.new
          Counter.send(:conditions_met?, object, :associations).should be_false
        end

        it "should be true when object is possible, not impossible" do
          object = Object.new
          Counter.add_possible_objects(object)
          Counter.add_impossible_object(object)
          Counter.send(:conditions_met?, object, :associations).should be_false
        end
      end
    end
  end
end
