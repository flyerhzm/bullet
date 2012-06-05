require 'spec_helper'

describe Object do
  context "bullet_ar_key" do
    it "should return class and id composition" do
      post = Post.first
      post.bullet_ar_key.should == "Post:#{post.id}"
    end

    if mongoid?
      it "should return class with namesapce and id composition" do
        post = Mongoid::Post.first
        post.bullet_ar_key.should == "Mongoid::Post:#{post.id}"
      end
    end
  end
end
