# frozen_string_literal: true

require 'spec_helper'

describe Bullet do
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
        before { Bullet.enable = false }

        it 'should be disabled' do
          expect(subject).to_not be_enable
        end

        context 'enable Bullet again without patching again the orms' do
          before do
            expect(Bullet::Mongoid).not_to receive(:enable) if defined?(Bullet::Mongoid)
            expect(Bullet::ActiveRecord).not_to receive(:enable) if defined?(Bullet::ActiveRecord)
            Bullet.enable = true
          end

          it 'should be enabled again' do
            expect(subject).to be_enable
          end
        end
      end
    end
  end

  # Testing the aliases.
  describe '#enabled' do
    context 'enable Bullet' do
      before do
        # Bullet.enable
        # Do nothing. Bullet has already been enabled for the whole test suite.
      end

      it 'should be enabled' do
        expect(subject).to be_enabled
      end

      context 'disable Bullet' do
        before { Bullet.enabled = false }

        it 'should be disabled' do
          expect(subject).to_not be_enabled
        end

        context 'enable Bullet again without patching again the orms' do
          before do
            expect(Bullet::Mongoid).not_to receive(:enabled) if defined?(Bullet::Mongoid)
            expect(Bullet::ActiveRecord).not_to receive(:enabled) if defined?(Bullet::ActiveRecord)
            Bullet.enabled = true
          end

          it 'should be enabled again' do
            expect(subject).to be_enabled
          end
        end
      end
    end
  end

  describe '#start?' do
    context 'when bullet is disabled' do
      before(:each) { Bullet.enable = false }

      it 'should not be started' do
        expect(Bullet).not_to be_start
      end
    end
  end

  describe '#pause and #resume' do
    before(:each) do
      Bullet.enable = true
      Bullet.start_request
    end

    after(:each) do
      Bullet.end_request
    end

    context 'when bullet is started' do
      it 'should be able to pause and resume' do
        expect(Bullet).to be_start
        Bullet.pause
        expect(Bullet).not_to be_start
        expect(Bullet).to be_paused
        Bullet.resume
        expect(Bullet).to be_start
        expect(Bullet).not_to be_paused
      end
    end

    context 'thread safety' do
      it 'should not affect other threads when paused' do
        Bullet.pause
        expect(Bullet).not_to be_start

        other_thread_result = nil
        Thread.new do
          Bullet.start_request
          other_thread_result = Bullet.start?
          Bullet.end_request
        end.join

        expect(other_thread_result).to be true
        expect(Bullet).not_to be_start
      end

      it 'should handle concurrent pause/resume correctly' do
        restore_logs = []
        threads = 10.times.map do |i|
          sleep(0.1 * i)
          Thread.new do
            Bullet.start_request
            was_started = Bullet.start?
            Bullet.pause if was_started
            sleep(0.2)
            restore_logs << "thread #{Thread.current.object_id}: restore from #{Bullet.start?} to #{was_started}"
            Bullet.resume if was_started
            Bullet.end_request
          end
        end

        threads.each(&:join)

        # All threads should have restored correctly
        restore_logs.each do |log|
          expect(log).to match(/restore from false to true/)
        end
      end
    end
  end

  describe '#skip' do
    before(:each) do
      Bullet.enable = true
      Bullet.start_request
    end

    after(:each) do
      Bullet.end_request
    end

    context 'when bullet is started' do
      it 'should pause bullet during block execution' do
        expect(Bullet).to be_start
        Bullet.skip do
          expect(Bullet).not_to be_start
          expect(Bullet).to be_paused
        end
        expect(Bullet).to be_start
        expect(Bullet).not_to be_paused
      end
    end

    context 'when bullet is not started' do
      before(:each) { Bullet.end_request }

      it 'should not change bullet state' do
        expect(Bullet).not_to be_start
        Bullet.skip do
          expect(Bullet).not_to be_start
        end
        expect(Bullet).not_to be_start
      end
    end

    context 'thread safety' do
      it 'should not affect other threads during skip' do
        expect(Bullet).to be_start

        other_thread_result = nil
        thread = Thread.new do
          Bullet.start_request
          sleep(0.1)
          other_thread_result = Bullet.start?
          Bullet.end_request
        end

        Bullet.skip do
          sleep(0.2)
          expect(Bullet).not_to be_start
        end

        thread.join

        expect(other_thread_result).to be true
        expect(Bullet).to be_start
      end

      it 'should handle concurrent skip blocks correctly' do
        restore_logs = []
        threads = 10.times.map do |i|
          sleep(0.1 * i)
          Thread.new do
            Bullet.start_request
            Bullet.skip do
              sleep(0.2)
              restore_logs << "thread #{Thread.current.object_id}: Bullet.start? = #{Bullet.start?}"
            end
            restore_logs << "thread #{Thread.current.object_id}: after skip Bullet.start? = #{Bullet.start?}"
            Bullet.end_request
          end
        end

        threads.each(&:join)

        # All threads should have been paused during skip and resumed after
        restore_logs.each do |log|
          if log.include?('Bullet.start? = false')
            expect(log).to match(/Bullet\.start\? = false/)
          elsif log.include?('after skip')
            expect(log).to match(/after skip Bullet\.start\? = true/)
          end
        end
      end
    end
  end

  describe '#debug' do
    before(:each) { $stdout = StringIO.new }

    after(:each) { $stdout = STDOUT }

    context 'when debug is enabled' do
      before(:each) { ENV['BULLET_DEBUG'] = 'true' }

      after(:each) { ENV['BULLET_DEBUG'] = 'false' }

      it 'should output debug information' do
        Bullet.debug('debug_message', 'this is helpful information')

        expect($stdout.string).to eq("[Bullet][debug_message] this is helpful information\n")
      end
    end

    context 'when debug is disabled' do
      it 'should output debug information' do
        Bullet.debug('debug_message', 'this is helpful information')

        expect($stdout.string).to be_empty
      end
    end
  end

  describe '#add_safelist' do
    context "for 'special' class names" do
      it 'is added to the safelist successfully' do
        Bullet.add_safelist(type: :n_plus_one_query, class_name: 'Klass', association: :department)
        expect(Bullet.get_safelist_associations(:n_plus_one_query, 'Klass')).to include :department
      end
    end

    context 'when association is registered as string (e.g., Action Text)' do
      it 'returns both symbol and string forms to match either' do
        Bullet.add_safelist(type: :unused_eager_loading, class_name: 'Note', association: :rich_text_content)
        safelist = Bullet.get_safelist_associations(:unused_eager_loading, 'Note')
        expect(safelist).to include(:rich_text_content)
        expect(safelist).to include('rich_text_content')
      end
    end
  end

  describe '#delete_safelist' do
    context "for 'special' class names" do
      it 'is deleted from the safelist successfully' do
        Bullet.add_safelist(type: :n_plus_one_query, class_name: 'Klass', association: :department)
        Bullet.delete_safelist(type: :n_plus_one_query, class_name: 'Klass', association: :department)
        expect(Bullet.safelist[:n_plus_one_query]).to eq({})
      end
    end

    context 'when exists multiple definitions' do
      it 'is deleted from the safelist successfully' do
        Bullet.add_safelist(type: :n_plus_one_query, class_name: 'Klass', association: :department)
        Bullet.add_safelist(type: :n_plus_one_query, class_name: 'Klass', association: :team)
        Bullet.delete_safelist(type: :n_plus_one_query, class_name: 'Klass', association: :team)
        expect(Bullet.get_safelist_associations(:n_plus_one_query, 'Klass')).to include :department
        expect(Bullet.get_safelist_associations(:n_plus_one_query, 'Klass')).to_not include :team
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
      let(:env) { { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/path', 'QUERY_STRING' => 'foo=bar' } }

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
