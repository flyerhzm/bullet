require 'spec_helper'

module Bullet
  module Notification
    describe CounterCache do
      subject { CounterCache.new(Post, [:comments, :votes]) }

      it { expect(subject.body).to eq('  Post => [:comments, :votes]') }
      it { expect(subject.title).to eq('Need Counter Cache') }
    end
  end
end
