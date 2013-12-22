require 'spec_helper'

module Bullet
  module Notification
    describe UnusedEagerLoading do
      subject { UnusedEagerLoading.new(Post, [:comments, :votes], "path") }

      describe '#body' do
        subject { super().body }
        it { should == "  Post => [:comments, :votes]\n  Remove from your finder: :include => [:comments, :votes]" }
      end

      describe '#title' do
        subject { super().title }
        it { should == "Unused Eager Loading in path" }
      end
    end
  end
end
