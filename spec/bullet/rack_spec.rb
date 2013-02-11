# encoding: utf-8
require 'spec_helper'

module Bullet
  describe Rack do
    let(:middleware) { Bullet::Rack.new app }
    let(:app) { Support::AppDouble.new }

    context "#html_request?" do
      it "should be true if Content-Type is text/html and http body contains html tag" do
        headers = {"Content-Type" => "text/html"}
        response = stub(:body => "<html><head></head><body></body></html>")
        middleware.should be_html_request(headers, response)
      end

      it "should be true if Content-Type is text/html and http body contains html tag with attributes" do
        headers = {"Content-Type" => "text/html"}
        response = stub(:body => "<html attr='hello'><head></head><body></body></html>")
        middleware.should be_html_request(headers, response)
      end

      it "should be false if there is no Content-Type header" do
        headers = {}
        response = stub(:body => "<html><head></head><body></body></html>")
        middleware.should_not be_html_request(headers, response)
      end

      it "should be false if Content-Type is javascript" do
        headers = {"Content-Type" => "text/javascript"}
        response = stub(:body => "<html><head></head><body></body></html>")
        middleware.should_not be_html_request(headers, response)
      end

      it "should be false if response body doesn't contain html tag" do
        headers = {"Content-Type" => "text/html"}
        response = stub(:body => "<div>Partial</div>")
        middleware.should_not be_html_request(headers, response)
      end
    end

    context "empty?" do
      it "should be false if response is a string and not empty" do
        response = stub(:body => "<html><head></head><body></body></html>")
        middleware.should_not be_empty(response)
      end

      it "should be tru if response is not found" do
        response = ["Not Found"]
        middleware.should be_empty(response)
      end

      it "should be true if response body is empty" do
        response = stub(:body => "")
        middleware.should be_empty(response)
      end
    end

    context "#call" do
      context "when Bullet is enabled" do
        it "should invoke Bullet.start_request and Bullet.end_request" do
          Bullet.should_receive(:start_request)
          Bullet.should_receive(:end_request)
          middleware.call([])
        end

        it "should return original response body" do
          expected_response = Support::ResponseDouble.new "Actual body"
          app.response = expected_response
          status, headers, response = middleware.call([])
          response.should == expected_response
        end

        it "should change response body if notification is active" do
          Bullet.should_receive(:notification?).and_return(true)
          Bullet.should_receive(:gather_inline_notifications).and_return("<bullet></bullet>")
          Bullet.should_receive(:perform_out_of_channel_notifications)
          status, headers, response = middleware.call([200, {"Content-Type" => "text/html"}])
          headers["Content-Length"].should == "56"
          response.should == ["<html><head></head><body></body></html><bullet></bullet>"]
        end

        it "should set the right Content-Length if response body contains accents" do
          response = Support::ResponseDouble.new
          response.body = "<html><head></head><body>é</body></html>"
          app.response = response
          Bullet.should_receive(:notification?).and_return(true)
          Bullet.should_receive(:gather_inline_notifications).and_return("<bullet></bullet>")
          status, headers, response = middleware.call([200, {"Content-Type" => "text/html"}])
          headers["Content-Length"].should == "58"
        end
      end

      context "when Bullet is disabled" do
        before(:each) { Bullet.stub(:enable?, false) }

        it "should not call Bullet.start_request" do
          Bullet.should_not_receive(:start_request)
          middleware.call([])
        end
      end
    end
  end
end
