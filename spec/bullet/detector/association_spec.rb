require 'spec_helper'

module Bullet
  module Detector
    describe Association do
      after(:each) { Association.clear }

      context ".start_request" do
        it "should set @@checked to false" do
          Association.start_request
          Association.class_variable_get(:@@checked).should be_false
        end
      end

      context ".clear" do
        it "should clear all class variables" do
          Association.clear
          Association.class_variable_get(:@@object_associations).should be_nil
          Association.class_variable_get(:@@callers).should be_nil
          Association.class_variable_get(:@@possible_objects).should be_nil
          Association.class_variable_get(:@@impossible_objects).should be_nil
          Association.class_variable_get(:@@call_object_associations).should be_nil
          Association.class_variable_get(:@@eager_loadings).should be_nil
        end
      end

      context ".add_object_association" do
        it "should add object, associations pair" do
          object = Object.new
          Association.add_object_associations(object, :associations)
          Association.send(:object_associations).should be_include(object, :associations)
        end
      end

      context ".add_call_object_associations" do
        it "should add call object, associations pair" do
          object = Object.new
          Association.add_call_object_associations(object, :associations)
          Association.send(:call_object_associations).should be_include(object, :associations)
        end
      end

      context ".add_possible_objects" do
        it "should add possible objects" do
          object1 = Object.new
          object2 = Object.new
          Association.add_possible_objects([object1, object2])
          Association.send(:possible_objects).should be_include(object1)
          Association.send(:possible_objects).should be_include(object2)
        end
      end

      context ".add_impossible_object" do
        it "should add impossible object" do
          object = Object.new
          Association.add_impossible_object(object)
          Association.send(:impossible_objects).should be_include(object)
        end
      end

      context ".add_eager_loadings" do
        before :each do
          @object1 = Object.new
          @object2 = Object.new
          Association.clear
        end

        it "should add objects, associations pair when eager_loadings are empty" do
          Association.add_eager_loadings([@object1, @object2], :associations)
          Association.send(:eager_loadings).should be_include([@object1, @object2], :associations)
        end

        it "should add objects, associations pair for existing eager_loadings" do
          Association.add_eager_loadings([@object1, @object2], :association1)
          Association.add_eager_loadings([@object1, @object2], :association2)
          Association.send(:eager_loadings).should be_include([@object1, @object2], :association1)
          Association.send(:eager_loadings).should be_include([@object1, @object2], :association2)
        end

        it "should merge objects, associations pair for existing eager_loadings" do
          Association.add_eager_loadings(@object1, :association1)
          Association.add_eager_loadings([@object1, @object2], :association2)
          Association.send(:eager_loadings).should be_include([@object1], :association1)
          Association.send(:eager_loadings).should be_include([@object1], :association2)
          Association.send(:eager_loadings).should be_include([@object1, @object2], :association2)
        end

        it "should delete objects, associations pair for existing eager_loadings" do
          Association.add_eager_loadings([@object1, @object2], :association1)
          Association.add_eager_loadings(@object1, :association2)
          Association.send(:eager_loadings).should be_include([@object1], :association1)
          Association.send(:eager_loadings).should be_include([@object1], :association2)
          Association.send(:eager_loadings).should be_include([@object2], :association1)
        end
      end
    end
  end
end
