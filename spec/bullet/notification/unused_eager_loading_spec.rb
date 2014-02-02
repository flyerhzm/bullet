require 'spec_helper'

module Bullet
  module Notification
    describe UnusedEagerLoading do
      subject { UnusedEagerLoading.new(Post, [:comments, :votes], "path") }

      it { expect(subject.body).to eq("  Post => [:comments, :votes]\n  Remove from your finder: :include => [:comments, :votes]") }
      it { expect(subject.title).to eq("Unused Eager Loading in path") }
    end
  end
end
