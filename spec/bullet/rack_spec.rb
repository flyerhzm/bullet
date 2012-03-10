require 'spec_helper'


describe Bullet::Rack do
  let(:middleware) { Bullet::Rack.new app }
  let(:app) { Support::AppDouble.new }

  describe "#call" do
    context "when Bullet is enabled" do
      before(:each) { Bullet.enable = true }

      it "should invoke Bullet.start_request" do
        Bullet.should_receive(:start_request)
        middleware.call([])
      end

      it "should invoke Bullet.end_request" do
        Bullet.should_receive(:end_request)
        middleware.call([])
      end

      it "should return original response body" do
        expected_response = Support::ResponseDouble.new "Actual body"
        app.response = expected_response
        status, headers, response = middleware.call([])
        response.should eq expected_response
      end
    end

    context "when Bullet is disabled" do
      before(:each) { Bullet.enable = false }
      after(:each) { Bullet.enable = true }

      it "should not call Bullet.start_request" do
        Bullet.should_not_receive(:start_request)
        middleware.call([])
      end
    end
  end
end
