require 'spec_helper'

describe Object do
  context "bullet_key" do
    it "should return class and id composition" do
      post = Post.first
      expect(post.bullet_key).to eq("Post:#{post.id}")
    end

    if mongoid?
      it "should return class with namesapce and id composition" do
        post = Mongoid::Post.first
        expect(post.bullet_key).to eq("Mongoid::Post:#{post.id}")
      end
    end
  end
end
