require 'spec_helper'

module Bullet
  module Notification
    describe Base do
      subject { Base.new(Post, [:comments, :votes]) }

      context "#title" do
        it "should raise NoMethodError" do
          lambda { subject.title }.should raise_error(NoMethodError)
        end
      end

      context "#body" do
        it "should raise NoMethodError" do
          lambda { subject.body }.should raise_error(NoMethodError)
        end
      end

      context "#whoami" do
        it "should display user name" do
          user = `whoami`.chomp
          subject.whoami.should == "user: #{user}"
        end
      end

      context "#body_with_caller" do
        it "should return body" do
          subject.stub(:body => "body")
          subject.body_with_caller.should == "body"
        end
      end

      context "#standard_notice" do
        it "should return title + body" do
          subject.stub(:title => "title", :body => "body")
          subject.standard_notice.should == "title\nbody"
        end
      end

      context "#full_notice" do
        it "should return whoami + url + title + body_with_caller" do
          subject.stub(:whoami => "whoami", :url => "url", :title => "title", :body_with_caller => "body_with_caller")
          subject.full_notice.should == "whoami\nurl\ntitle\nbody_with_caller"
        end
      end

      context "#notify_inline" do
        it "should send full_notice to notifier" do
          notifier = stub
          subject.stub(:notifier => notifier, :full_notice => "full_notice")
          notifier.should_receive(:inline_notify).with("full_notice")
          subject.notify_inline
        end
      end

      context "#notify_out_of_channel" do
        it "should send full_out_of_channel to notifier" do
          notifier = stub
          subject.stub(:notifier => notifier, :full_notice => "full_notice")
          notifier.should_receive(:out_of_channel_notify).with("full_notice")
          subject.notify_out_of_channel
        end
      end
    end
  end
end
