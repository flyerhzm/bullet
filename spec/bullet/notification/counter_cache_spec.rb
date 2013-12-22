require 'spec_helper'

module Bullet
  module Notification
    describe CounterCache do
      subject { CounterCache.new(Post, [:comments, :votes]) }

      describe '#body' do
        subject { super().body }
        it { should == "  Post => [:comments, :votes]" }
      end

      describe '#title' do
        subject { super().title }
        it { should == "Need Counter Cache" }
      end
    end
  end
end
