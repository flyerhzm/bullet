# frozen_string_literal: true

module Bullet
  module Ext
    module String
      refine ::String do
        def bullet_class_name
          sub(/:[^:]*?$/, '')
        end
      end
    end
  end
end
