require 'spec_helper'


module Bullet
  module Registry
    describe Object do
      let(:post) { Post.first }
      let(:another_post) { Post.last }
      subject { Object.new.tap { |object| object.add(post.ar_key) } }

      context "#include?" do
        it "should include the object" do
          subject.should be_include(post.ar_key)
        end
      end

      context "#add" do
        it "should add an object" do
          subject.add(another_post.ar_key)
          subject.should be_include(another_post.ar_key)
        end

        it "should add an array of objects" do
          subject.add([post.ar_key, another_post.ar_key])
          subject.should be_include(post.ar_key)
          subject.should be_include(another_post.ar_key)
        end
      end
    end
  end
end
