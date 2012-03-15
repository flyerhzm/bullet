require 'spec_helper'

module Bullet
  module Detector
    describe Base do
      context ".end_request" do
        it "should call clear" do
          Base.should_receive(:clear)
          Base.end_request
        end
      end
    end
  end
end
