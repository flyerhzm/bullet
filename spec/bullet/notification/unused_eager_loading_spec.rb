# frozen_string_literal: true

require 'spec_helper'

module Bullet
  module Notification
    describe UnusedEagerLoading do
      subject { UnusedEagerLoading.new([''], Post, %i[comments votes], 'path') }

      it { expect(subject.body).to eq("  Post => [:comments, :votes]\n  Remove from your finder: :includes => [:comments, :votes]") }
      it { expect(subject.title).to eq('AVOID eager loading in path') }
    end
  end
end
