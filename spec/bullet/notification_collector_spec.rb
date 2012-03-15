require 'spec_helper'

module Bullet
  describe NotificationCollector do
    subject { NotificationCollector.new.tap { |collector| collector.add("value") } }

    context "#add" do
      it "should add a value" do
        subject.add("value1")
        subject.collection.should be_include("value1")
      end
    end

    context "#reset" do
      it "should reset collector" do
        subject.reset
        subject.collection.should be_empty
      end
    end

    context "#notifications_present?" do
      it "should be true if collection is not empty" do
        subject.should be_notifications_present
      end

      it "should be false if collection is empty" do
        subject.reset
        subject.should_not be_notifications_present
      end
    end
  end
end
