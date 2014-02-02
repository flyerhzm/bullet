require 'spec_helper'

module Bullet
  module Notification
    describe NPlusOneQuery do
      subject { NPlusOneQuery.new([["caller1", "caller2"]], Post, [:comments, :votes], "path") }

      it { expect(subject.body_with_caller).to eq("  Post => [:comments, :votes]\n  Add to your finder: :include => [:comments, :votes]\nN+1 Query method call stack\n  caller1\n  caller2") }
      it { expect(subject.body).to eq("  Post => [:comments, :votes]\n  Add to your finder: :include => [:comments, :votes]") }
      it { expect(subject.title).to eq("N+1 Query in path") }
    end
  end
end
