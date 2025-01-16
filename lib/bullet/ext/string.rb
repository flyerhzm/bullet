# frozen_string_literal: true

module Bullet
  module Ext
    module String
      refine ::String do
        attr_reader :bullet_class_name

        def bullet_class_name
          @bullet_class_name ||= begin
            last_colon = self.rindex(':')
            last_colon ? self[0...last_colon] : self
          end
        end
      end
    end
  end
end
