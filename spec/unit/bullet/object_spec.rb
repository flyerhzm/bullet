require 'spec_helper'

describe Bullet::Object do
  context "ActiveRecord::Base" do
    let(:post) { Post.create(:title => 'post')}
    let(:bullet_object) { post.to_bullet_object }

    it "'Post' => post.id" do
      bullet_object["Post"].should == post.id
    end
  end

  context "Array" do
    let(:posts) { [Post.create(:title => 'post1'), Post.create(:title => 'post2')] }
    let(:bullet_object) { posts.to_bullet_object }

    it "'Post' => [post1.id, post2.id]" do
      bullet_object["Post"].should == posts.collect(&:id)
    end
  end
end
