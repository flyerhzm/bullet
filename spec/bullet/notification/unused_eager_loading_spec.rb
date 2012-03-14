require 'spec_helper'

module Bullet
  module Notification
    describe UnusedEagerLoading do
      subject { UnusedEagerLoading.new(Post, [:comments, :votes], "path") }

      its(:body) { should == "  Post => [:comments, :votes]\n  Remove from your finder: :include => [:comments, :votes]" }
      its(:title) { should == "Unused Eager Loading in path" }
    end
  end
end
