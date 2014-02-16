require 'spec_helper'

module Bullet
  module Detector
    describe Association do
      before :all do
        @post1 = Post.first
        @post2 = Post.last
      end
      before(:each) { Association.clear }

      context ".start_request" do
        it "should set @@checked to false" do
          Association.start_request
          expect(Association.class_variable_get(:@@checked)).to eq false
        end
      end

      context ".clear" do
        it "should clear all class variables" do
          Association.clear
          expect(Association.class_variable_get(:@@object_associations)).to be_nil
          expect(Association.class_variable_get(:@@possible_objects)).to be_nil
          expect(Association.class_variable_get(:@@impossible_objects)).to be_nil
          expect(Association.class_variable_get(:@@call_object_associations)).to be_nil
          expect(Association.class_variable_get(:@@eager_loadings)).to be_nil
        end
      end

      context ".add_object_association" do
        it "should add object, associations pair" do
          Association.add_object_associations(@post1, :associations)
          expect(Association.send(:object_associations)).to be_include(@post1.bullet_ar_key, :associations)
        end
      end

      context ".add_call_object_associations" do
        it "should add call object, associations pair" do
          Association.add_call_object_associations(@post1, :associations)
          expect(Association.send(:call_object_associations)).to be_include(@post1.bullet_ar_key, :associations)
        end
      end
    end
  end
end
