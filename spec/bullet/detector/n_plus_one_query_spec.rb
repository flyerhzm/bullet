require 'spec_helper'

module Bullet
  module Detector
    describe NPlusOneQuery do
      before(:all) do
        @post = Post.first
        @post2 = Post.last
      end
      before(:each) { NPlusOneQuery.clear }

      context ".call_association" do
        it "should set @@checked to true" do
          NPlusOneQuery.call_association(@post, :associations)
          NPlusOneQuery.class_variable_get(:@@checked).should be_true
        end

        it "should add call_object_associations" do
          NPlusOneQuery.should_receive(:add_call_object_associations).with(@post, :associations)
          NPlusOneQuery.call_association(@post, :associations)
        end
      end

      context ".possible?" do
        it "should be true if possible_objects contain" do
          NPlusOneQuery.add_possible_objects(@post)
          NPlusOneQuery.send(:possible?, @post.bullet_ar_key).should be_true
        end
      end

      context ".impossible?" do
        it "should be true if impossible_objects contain" do
          NPlusOneQuery.add_impossible_object(@post)
          NPlusOneQuery.send(:impossible?, @post.bullet_ar_key).should be_true
        end
      end

      context ".association?" do
        it "should be true if object, associations pair is already existed" do
          NPlusOneQuery.add_object_associations(@post, :association)
          NPlusOneQuery.send(:association?, @post.bullet_ar_key, :association).should be_true
        end

        it "should be false if object, association pair is not existed" do
          NPlusOneQuery.add_object_associations(@post, :association1)
          NPlusOneQuery.send(:association?, @post.bullet_ar_key, :associatio2).should be_false
        end
      end

      context ".conditions_met?" do
        it "should be true if object is possible, not impossible and object, associations pair is not already existed" do
          NPlusOneQuery.stub(:possible?).with(@post.bullet_ar_key).and_return(true)
          NPlusOneQuery.stub(:impossible?).with(@post.bullet_ar_key).and_return(false)
          NPlusOneQuery.stub(:association?).with(@post.bullet_ar_key, :associations).and_return(false)
          NPlusOneQuery.send(:conditions_met?, @post.bullet_ar_key, :associations).should be_true
        end

        it "should be false if object is not possible, not impossible and object, associations pair is not already existed" do
          NPlusOneQuery.stub(:possible?).with(@post.bullet_ar_key).and_return(false)
          NPlusOneQuery.stub(:impossible?).with(@post.bullet_ar_key).and_return(false)
          NPlusOneQuery.stub(:association?).with(@post.bullet_ar_key, :associations).and_return(false)
          NPlusOneQuery.send(:conditions_met?, @post.bullet_ar_key, :associations).should be_false
        end

        it "should be false if object is possible, but impossible and object, associations pair is not already existed" do
          NPlusOneQuery.stub(:possible?).with(@post.bullet_ar_key).and_return(true)
          NPlusOneQuery.stub(:impossible?).with(@post.bullet_ar_key).and_return(true)
          NPlusOneQuery.stub(:association?).with(@post.bullet_ar_key, :associations).and_return(false)
          NPlusOneQuery.send(:conditions_met?, @post.bullet_ar_key, :associations).should be_false
        end

        it "should be false if object is possible, not impossible and object, associations pair is already existed" do
          NPlusOneQuery.stub(:possible?).with(@post.bullet_ar_key).and_return(true)
          NPlusOneQuery.stub(:impossible?).with(@post.bullet_ar_key).and_return(false)
          NPlusOneQuery.stub(:association?).with(@post.bullet_ar_key, :associations).and_return(true)
          NPlusOneQuery.send(:conditions_met?, @post.bullet_ar_key, :associations).should be_false
        end
      end

      context ".call_association" do
        it "should create notification if conditions met" do
          NPlusOneQuery.should_receive(:conditions_met?).with(@post.bullet_ar_key, :association).and_return(true)
          NPlusOneQuery.should_receive(:caller_in_project).and_return(["caller"])
          NPlusOneQuery.should_receive(:create_notification).with(["caller"], "Post", :association)
          NPlusOneQuery.call_association(@post, :association)
        end

        it "should not create notification if conditions not met" do
          NPlusOneQuery.should_receive(:conditions_met?).with(@post.bullet_ar_key, :association).and_return(false)
          NPlusOneQuery.should_not_receive(:caller_in_project!)
          NPlusOneQuery.should_not_receive(:create_notification).with("Post", :association)
          NPlusOneQuery.call_association(@post, :association)
        end
      end

      context ".add_possible_objects" do
        it "should add possible objects" do
          NPlusOneQuery.add_possible_objects([@post, @post2])
          NPlusOneQuery.send(:possible_objects).should be_include(@post.bullet_ar_key)
          NPlusOneQuery.send(:possible_objects).should be_include(@post2.bullet_ar_key)
        end

        it "should not raise error if object is nil" do
          lambda { NPlusOneQuery.add_possible_objects(nil) }.should_not raise_error
        end
      end

      context ".add_impossible_object" do
        it "should add impossible object" do
          NPlusOneQuery.add_impossible_object(@post)
          NPlusOneQuery.send(:impossible_objects).should be_include(@post.bullet_ar_key)
        end
      end
    end
  end
end
