module Bullet
  module Notification
    class NPlusOneQuery < Base
      def initialize(callers, base_class, associations, path = nil)
        super(base_class, associations, path)

        @callers = callers
      end

      def body
        "#{klazz_associations_str}\n  Add to your finder: #{associations_str}"
      end

      def title
        "N+1 Query #{@path ? "in #{@path}" : 'detected'}"
      end

      def notification_data
        super.merge(
          :backtrace => @callers
        )
      end

      protected
        def call_stack_messages
          (['N+1 Query method call stack'] + @callers).join( "\n  " )
        end
    end
  end
end
