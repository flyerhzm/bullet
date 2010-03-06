require 'rubygems'
require 'rspec'
require 'rspec/autorun'
require 'rails'
require 'active_record'
require 'action_controller'

module Rails
  class <<self
    def root
      File.expand_path(__FILE__).split('/')[0..-3].join('/')
    end
  end
end

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
require 'bullet'
Bullet.enable = true
ActiveRecord::Migration.verbose = false

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
