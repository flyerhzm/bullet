require 'spec_helper'

describe Bullet, focused: true do
  subject { Bullet }

  describe '#enable' do
    context 'enable Bullet' do
      before do
        # Bullet.enable
        # Do nothing. Bullet has already been enabled for the whole test suite.
      end

      it 'should be enabled' do
        expect(subject).to be_enable
      end

      context 'disable Bullet' do
        before do
          Bullet.enable = false
        end

        it 'should be disabled' do
          expect(subject).to_not be_enable
        end

        context 'enable Bullet again without patching again the orms' do
          before do
            expect(Bullet::Mongoid).not_to receive(:enable) if defined? Bullet::Mongoid
            expect(Bullet::ActiveRecord).not_to receive(:enable) if defined? Bullet::ActiveRecord
            Bullet.enable = true
          end

          it 'should be enabled again' do
            expect(subject).to be_enable
          end
        end
      end
    end
  end

  describe '#start?' do
    context 'when bullet is disabled' do
      before(:each) do
        Bullet.enable = false
      end

      it 'should not be started' do
        expect(Bullet).not_to be_start
      end
    end
  end

  describe '#debug' do
    before(:each) do
      $stdout = StringIO.new
    end

    after(:each) do
      $stdout = STDOUT
    end

    context 'when debug is enabled' do
      before(:each) do
        ENV['BULLET_DEBUG'] = 'true'
      end

      after(:each) do
        ENV['BULLET_DEBUG'] = 'false'
      end

      it 'should output debug information' do
        Bullet.debug('debug_message', 'this is helpful information')

        expect($stdout.string)
          .to eq("[Bullet][debug_message] this is helpful information\n")
      end
    end

    context 'when debug is disabled' do
      it 'should output debug information' do
        Bullet.debug('debug_message', 'this is helpful information')

        expect($stdout.string).to be_empty
      end
    end
  end

  describe '#add_whitelist' do
    context "for 'special' class names" do
      it 'is added to the whitelist successfully' do
        Bullet.add_whitelist(:type => :n_plus_one_query, :class_name => 'Klass', :association => :department)
        expect(Bullet.get_whitelist_associations(:n_plus_one_query, 'Klass')).to include :department
      end
    end
  end

  describe '#perform_out_of_channel_notifications' do
    let(:notification) { double }

    before do
      allow(Bullet).to receive(:for_each_active_notifier_with_notification).and_yield(notification)
      allow(notification).to receive(:notify_out_of_channel)
    end

    context 'when called with Rack environment hash' do
      let(:env) {
        {
          'REQUEST_METHOD' => 'GET',
          'PATH_INFO' => '/path',
          'QUERY_STRING' => 'foo=bar',
        }
      }

      context "when env['REQUEST_URI'] is nil" do
        before { env['REQUEST_URI'] = nil }

        it 'should notification.url is built' do
          expect(notification).to receive(:url=).with('GET /path?foo=bar')
          Bullet.perform_out_of_channel_notifications(env)
        end
      end

      context "when env['REQUEST_URI'] is present" do
        before { env['REQUEST_URI'] = 'http://example.com/path' }

        it "should notification.url is env['REQUEST_URI']" do
          expect(notification).to receive(:url=).with('GET http://example.com/path')
          Bullet.perform_out_of_channel_notifications(env)
        end
      end
    end
  end
end
