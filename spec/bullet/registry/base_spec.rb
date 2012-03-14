require 'spec_helper'

module Bullet
  module Registry
    describe Base do
      subject { Base.new.tap { |base| base.add("key", "value") } }

      context "#[]" do
        it "should get value by key" do
          subject["key"].should == Set.new(["value"])
        end
      end

      context "#delete" do
        it "should delete key" do
          subject.delete("key")
          subject["key"].should be_nil
        end
      end

      context "#add" do
        it "should add value with string" do
          subject.add("key", "new_value")
          subject["key"].should == Set.new(["value", "new_value"])
        end

        it "should add value with array" do
          subject.add("key", ["value1", "value2"])
          subject["key"].should == Set.new(["value", "value1", "value2"])
        end
      end

      context "#include?" do
        it "should include key/value" do
          subject.include?("key", "value").should be_true
        end

        it "should not include wrong key/value" do
          subject.include?("key", "val").should be_false
        end
      end
    end
  end
end
