require 'spec_helper'

module Bullet
  module Notification
    describe Base do
      subject { Base.new(Post, [:comments, :votes]) }

      context "#title" do
        it "should raise NoMethodError" do
          expect { subject.title }.to raise_error(NoMethodError)
        end
      end

      context "#body" do
        it "should raise NoMethodError" do
          expect { subject.body }.to raise_error(NoMethodError)
        end
      end

      context "#whoami" do
        it "should display user name" do
          user = `whoami`.chomp
          expect(subject.whoami).to eq("user: #{user}")
        end

        it "should leverage ENV parameter" do
          temp_env_variable("USER", "bogus") do
            expect(subject.whoami).to eq("user: bogus")
          end
        end

        it "should return blank if no user available" do
          temp_env_variable("USER","") do
            expect(subject).to receive(:`).with("whoami").and_return("")
            expect(subject.whoami).to eq("")
          end
        end

        it "should return blank if whoami is not available" do
          temp_env_variable("USER","") do
            expect(subject).to receive(:`).with("whoami").and_raise(Errno::ENOENT)
            expect(subject.whoami).to eq("")
          end
        end

        def temp_env_variable(name, value)
          old_value = ENV[name]
          ENV[name] = value
          yield
        ensure
          ENV[name] = old_value
        end

      end

      context "#body_with_caller" do
        it "should return body" do
          allow(subject).to receive(:body).and_return("body")
          expect(subject.body_with_caller).to eq("body")
        end
      end

      context "#standard_notice" do
        it "should return title + body" do
          allow(subject).to receive(:title).and_return("title")
          allow(subject).to receive(:body).and_return("body")
          expect(subject.standard_notice).to eq("title\nbody")
        end
      end

      context "#full_notice" do
        it "should return whoami + url + title + body_with_caller" do
          allow(subject).to receive(:whoami).and_return("whoami")
          allow(subject).to receive(:url).and_return("url")
          allow(subject).to receive(:title).and_return("title")
          allow(subject).to receive(:body_with_caller).and_return("body_with_caller")
          expect(subject.full_notice).to eq("whoami\nurl\ntitle\nbody_with_caller")
        end

        it "should return url + title + body_with_caller" do
          allow(subject).to receive(:whoami).and_return("")
          allow(subject).to receive(:url).and_return("url")
          allow(subject).to receive(:title).and_return("title")
          allow(subject).to receive(:body_with_caller).and_return("body_with_caller")
          expect(subject.full_notice).to eq("url\ntitle\nbody_with_caller")
        end
      end

      context "#notification_data" do
        it "should return notification data" do
          allow(subject).to receive(:whoami).and_return("whoami")
          allow(subject).to receive(:url).and_return("url")
          allow(subject).to receive(:title).and_return("title")
          allow(subject).to receive(:body_with_caller).and_return("body_with_caller")
          expect(subject.notification_data).to eq(:user => "whoami", :url => "url", :title => "title", :body => "body_with_caller")
        end
      end

      context "#notify_inline" do
        it "should send full_notice to notifier" do
          notifier = double
          allow(subject).to receive(:notifier).and_return(notifier)
          allow(subject).to receive(:notification_data).and_return(:foo => :bar)
          expect(notifier).to receive(:inline_notify).with(:foo => :bar)
          subject.notify_inline
        end
      end

      context "#notify_out_of_channel" do
        it "should send full_out_of_channel to notifier" do
          notifier = double
          allow(subject).to receive(:notifier).and_return(notifier)
          allow(subject).to receive(:notification_data).and_return(:foo => :bar)
          expect(notifier).to receive(:out_of_channel_notify).with(:foo => :bar)
          subject.notify_out_of_channel
        end
      end
    end
  end
end
