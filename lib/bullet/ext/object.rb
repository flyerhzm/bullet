# frozen_string_literal: true

module Bullet
  module Ext
    refine Object do
      def bullet_key
        "#{self.class}:#{bullet_primary_key_value}"
      end

      def bullet_primary_key_value
        return if respond_to?(:persisted?) && !persisted?

        if self.class.respond_to?(:primary_keys) && self.class.primary_keys
          self.class.primary_keys.map { |primary_key| send primary_key }.join(',')
        elsif self.class.respond_to?(:primary_key) && self.class.primary_key
          send self.class.primary_key
        else
          id
        end
      end
    end
  end
end
