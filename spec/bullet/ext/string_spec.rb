require 'spec_helper'

describe String do
  context "bullet_class_name" do
    it "should only return class name" do
      "Post:1".bullet_class_name.should == "Post"
    end

    it "should return class name with namespace" do
      "Mongoid::Post:1234567890".bullet_class_name.should == "Mongoid::Post"
    end
  end
end
