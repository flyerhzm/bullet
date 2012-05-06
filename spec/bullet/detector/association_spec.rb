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
          Association.class_variable_get(:@@checked).should be_false
        end
      end

      context ".clear" do
        it "should clear all class variables" do
          Association.clear
          Association.class_variable_get(:@@object_associations).should be_nil
          Association.class_variable_get(:@@possible_objects).should be_nil
          Association.class_variable_get(:@@impossible_objects).should be_nil
          Association.class_variable_get(:@@call_object_associations).should be_nil
          Association.class_variable_get(:@@eager_loadings).should be_nil
        end
      end

      context ".add_object_association" do
        it "should add object, associations pair" do
          Association.add_object_associations(@post1, :associations)
          Association.send(:object_associations).should be_include(@post1.bullet_ar_key, :associations)
        end
      end

      context ".add_call_object_associations" do
        it "should add call object, associations pair" do
          Association.add_call_object_associations(@post1, :associations)
          Association.send(:call_object_associations).should be_include(@post1.bullet_ar_key, :associations)
        end
      end

      context ".add_possible_objects" do
        it "should add possible objects" do
          Association.add_possible_objects([@post1, @post2])
          Association.send(:possible_objects).should be_include(@post1.bullet_ar_key)
          Association.send(:possible_objects).should be_include(@post2.bullet_ar_key)
        end

        it "should not raise error if object is nil" do
          lambda { Association.add_possible_objects(nil) }.should_not raise_error
        end
      end

      context ".add_impossible_object" do
        it "should add impossible object" do
          Association.add_impossible_object(@post1)
          Association.send(:impossible_objects).should be_include(@post1.bullet_ar_key)
        end
      end

      context ".add_eager_loadings" do
        it "should add objects, associations pair when eager_loadings are empty" do
          Association.add_eager_loadings([@post1, @post2], :associations)
          Association.send(:eager_loadings).should be_include([@post1.bullet_ar_key, @post2.bullet_ar_key], :associations)
        end

        it "should add objects, associations pair for existing eager_loadings" do
          Association.add_eager_loadings([@post1, @post2], :association1)
          Association.add_eager_loadings([@post1, @post2], :association2)
          Association.send(:eager_loadings).should be_include([@post1.bullet_ar_key, @post2.bullet_ar_key], :association1)
          Association.send(:eager_loadings).should be_include([@post1.bullet_ar_key, @post2.bullet_ar_key], :association2)
        end

        it "should merge objects, associations pair for existing eager_loadings" do
          Association.add_eager_loadings([@post1], :association1)
          Association.add_eager_loadings([@post1, @post2], :association2)
          Association.send(:eager_loadings).should be_include([@post1.bullet_ar_key], :association1)
          Association.send(:eager_loadings).should be_include([@post1.bullet_ar_key], :association2)
          Association.send(:eager_loadings).should be_include([@post1.bullet_ar_key, @post2.bullet_ar_key], :association2)
        end

        it "should delete objects, associations pair for existing eager_loadings" do
          Association.add_eager_loadings([@post1, @post2], :association1)
          Association.add_eager_loadings([@post1], :association2)
          Association.send(:eager_loadings).should be_include([@post1.bullet_ar_key], :association1)
          Association.send(:eager_loadings).should be_include([@post1.bullet_ar_key], :association2)
          Association.send(:eager_loadings).should be_include([@post2.bullet_ar_key], :association1)
        end
      end
    end
  end
end
