require 'spec_helper'

module Bullet
  module Detector
    describe NPlusOneQuery do
      before(:each) { @object = Object.new }
      after(:each) { NPlusOneQuery.clear }

      context ".call_association" do
        it "should set @@checked to true" do
          NPlusOneQuery.call_association(@object, :associations)
          NPlusOneQuery.class_variable_get(:@@checked).should be_true
        end

        it "should add call_object_associations" do
          NPlusOneQuery.should_receive(:add_call_object_associations).with(@object, :associations)
          NPlusOneQuery.call_association(@object, :associations)
        end
      end

      context ".possible?" do
        it "should be true if possible_objects contain" do
          NPlusOneQuery.add_possible_objects(@object)
          NPlusOneQuery.send(:possible?, @object).should be_true
        end
      end

      context ".impossible?" do
        it "should be true if impossible_objects contain" do
          NPlusOneQuery.add_impossible_object(@object)
          NPlusOneQuery.send(:impossible?, @object).should be_true
        end
      end

      context ".association?" do
        it "should be true if object, associations pair is already existed" do
          NPlusOneQuery.add_object_associations(@object, :association)
          NPlusOneQuery.send(:association?, @object, :association).should be_true
        end

        it "should be false if object, association pair is not existed" do
          NPlusOneQuery.add_object_associations(@object, :association1)
          NPlusOneQuery.send(:association?, @object, :associatio2).should be_false
        end
      end

      context ".conditions_met?" do
        it "should be true if object is possible, not impossible and object, associations pair is not already existed" do
          NPlusOneQuery.stub(:possible?).with(@object).and_return(true)
          NPlusOneQuery.stub(:impossible?).with(@object).and_return(false)
          NPlusOneQuery.stub(:association?).with(@object, :associations).and_return(false)
          NPlusOneQuery.send(:conditions_met?, @object, :associations).should be_true
        end

        it "should be false if object is not possible, not impossible and object, associations pair is not already existed" do
          NPlusOneQuery.stub(:possible?).with(@object).and_return(false)
          NPlusOneQuery.stub(:impossible?).with(@object).and_return(false)
          NPlusOneQuery.stub(:association?).with(@object, :associations).and_return(false)
          NPlusOneQuery.send(:conditions_met?, @object, :associations).should be_false
        end

        it "should be false if object is possible, but impossible and object, associations pair is not already existed" do
          NPlusOneQuery.stub(:possible?).with(@object).and_return(true)
          NPlusOneQuery.stub(:impossible?).with(@object).and_return(true)
          NPlusOneQuery.stub(:association?).with(@object, :associations).and_return(false)
          NPlusOneQuery.send(:conditions_met?, @object, :associations).should be_false
        end

        it "should be false if object is possible, not impossible and object, associations pair is already existed" do
          NPlusOneQuery.stub(:possible?).with(@object).and_return(true)
          NPlusOneQuery.stub(:impossible?).with(@object).and_return(false)
          NPlusOneQuery.stub(:association?).with(@object, :associations).and_return(true)
          NPlusOneQuery.send(:conditions_met?, @object, :associations).should be_false
        end
      end

      context ".call_association" do
        it "should create notification if conditions met" do
          NPlusOneQuery.should_receive(:conditions_met?).with(@object, :association).and_return(true)
          NPlusOneQuery.should_receive(:caller_in_project!)
          NPlusOneQuery.should_receive(:create_notification).with(Object, :association)
          NPlusOneQuery.call_association(@object, :association)
        end

        it "should not create notification if conditions not met" do
          NPlusOneQuery.should_receive(:conditions_met?).with(@object, :association).and_return(false)
          NPlusOneQuery.should_not_receive(:caller_in_project!)
          NPlusOneQuery.should_not_receive(:create_notification).with(Object, :association)
          NPlusOneQuery.call_association(@object, :association)
        end
      end
    end
  end
end
