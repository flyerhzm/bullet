# frozen_string_literal: true

require 'spec_helper'

module Bullet
  RSpec.describe StackTraceFilter do
    let(:dummy_class) { Class.new { extend StackTraceFilter } }
    let(:root_path) { Dir.pwd }
    let(:bundler_path) { Bundler.bundle_path }

    describe '#caller_in_project' do
      it 'gets the caller in the project' do
        expect(dummy_class).to receive(:call_stacks).and_return({
          'Post:1' => [
            File.join(root_path, 'lib/bullet.rb'),
            File.join(root_path, 'vendor/uniform_notifier.rb'),
            File.join(bundler_path, 'rack.rb')
          ]
        })
        expect(dummy_class.caller_in_project('Post:1')).to eq([
          File.join(root_path, 'lib/bullet.rb')
        ])
      end
    end
  end
end