require 'spec_helper'


module Bullet
  module Registry
    class Post; end

    describe Object do
      let(:post) { Post.new }
      subject { Object.new.tap { |object| object.add(post) } }

      context "#include?" do
        it "should include the object" do
          subject.should be_include(post)
        end
      end

      context "#add" do
        it "should add an object" do
          post1 = Post.new
          subject.add(post1)
          subject.should be_include(post1)
        end

        it "should add an array of objects" do
          post1 = Post.new
          post2 = Post.new
          subject.add([post1, post2])
          subject.should be_include(post1)
          subject.should be_include(post2)
        end
      end
    end
  end
end
