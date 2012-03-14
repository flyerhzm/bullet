require 'spec_helper'

module Bullet
  module Notification
    describe NPlusOneQuery do
      subject { NPlusOneQuery.new([["caller1", "caller2"]], Post, [:comments, :votes], "path") }

      its(:body_with_caller) { should == "  Post => [:comments, :votes]\n  Add to your finder: :include => [:comments, :votes]\nN+1 Query method call stack\n  caller1\n  caller2" }
      its(:body) { should == "  Post => [:comments, :votes]\n  Add to your finder: :include => [:comments, :votes]" }
      its(:title) { should == "N+1 Query in path" }
    end
  end
end
