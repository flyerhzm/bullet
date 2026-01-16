# frozen_string_literal: true

module Bullet
  module Registry
    class CallStack < Base
      # remembers found association backtrace
      # if backtrace is provided, it will be used and override any existing value
      def add(key, backtrace = nil)
        if backtrace
          @registry[key] = backtrace
        else
          @registry[key] ||= Thread.current.backtrace
        end
      end
    end
  end
end
