require 'spec_helper'

module Bullet
  module Notification
    describe NPlusOneQuery do
      subject { NPlusOneQuery.new([['caller1', 'caller2']], Post, [:comments, :votes], 'path') }

      it { expect(subject.body_with_caller).to eq("  Post => [:comments, :votes]\n  Add to your finder: :includes => [:comments, :votes]\nCall stack\n  caller1\n  caller2\n") }
      it { expect([subject.body_with_caller, subject.body_with_caller]).to eq(["  Post => [:comments, :votes]\n  Add to your finder: :includes => [:comments, :votes]\nCall stack\n  caller1\n  caller2\n", "  Post => [:comments, :votes]\n  Add to your finder: :includes => [:comments, :votes]\nCall stack\n  caller1\n  caller2\n"]) }
      it { expect(subject.body).to eq("  Post => [:comments, :votes]\n  Add to your finder: :includes => [:comments, :votes]") }
      it { expect(subject.title).to eq('USE eager loading in path') }
    end
  end
end
