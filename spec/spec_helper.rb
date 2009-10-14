require 'rubygems'
require 'spec/autorun'
require 'active_record'
require 'action_controller'

module Rails
  module VERSION 
    STRING = "2.3.2"
  end
end

RAILS_ROOT = File.expand_path(__FILE__).split('/')[0..-3].join('/') unless defined? RAILS_ROOT
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/notification'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/logger'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/active_record'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/action_controller'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/association'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet/counter'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bullet'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/bulletware'))
Bullet.enable = true

module BulletTestHelper
  def silence_logger(&block)
    orig_stdout = $stdout
    $stdout = StringIO.new
    block.call
    $stdout = orig_stdout
  end
end

module Bullet
  class Association
    class <<self
      # returns true if all associations are preloaded
      def completely_preloading_associations?
        !has_unpreload_associations?
      end

      # returns true if a given object has a specific association
      def creating_object_association_for?(object, association)
        object_associations[object].present? && object_associations[object].include?(association)
      end

      # returns true if a given class includes the specific unpreloaded association
      def detecting_unpreloaded_association_for?(klazz, association)
        unpreload_associations[klazz].present? && unpreload_associations[klazz].include?(association)
      end

      # returns true if the given class includes the specific unused preloaded association
      def unused_preload_associations_for?(klazz, association)
         unused_preload_associations[klazz].present? && unused_preload_associations[klazz].include?(association)
      end
    end
  end
end
