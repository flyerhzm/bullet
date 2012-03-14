require 'spec_helper'

module Bullet
  module Notification
    describe CounterCache do
      subject { CounterCache.new(Post, [:comments, :votes]) }

      its(:body) { should == "  Post => [:comments, :votes]" }
      its(:title) { should == "Need Counter Cache" }
    end
  end
end
