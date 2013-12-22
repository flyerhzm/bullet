require 'spec_helper'

module Bullet
  module Notification
    describe NPlusOneQuery do
      subject { NPlusOneQuery.new([["caller1", "caller2"]], Post, [:comments, :votes], "path") }

      describe '#body_with_caller' do
        subject { super().body_with_caller }
        it { should == "  Post => [:comments, :votes]\n  Add to your finder: :include => [:comments, :votes]\nN+1 Query method call stack\n  caller1\n  caller2" }
      end

      describe '#body' do
        subject { super().body }
        it { should == "  Post => [:comments, :votes]\n  Add to your finder: :include => [:comments, :votes]" }
      end

      describe '#title' do
        subject { super().title }
        it { should == "N+1 Query in path" }
      end
    end
  end
end
