module Bullet
  module Notification
    class NPlusOneQuery < Base
      def initialize(callers, base_class, associations, path = nil)
        super(base_class, associations, path)

        @callers = callers
      end

      def body_with_caller
        "#{body}\n#{call_stack_messages}"
      end

      def body
        "#{klazz_associations_str}\n  Add to your finder: #{associations_str}"
      end

      def title
        "N+1 Query #{@path ? "in #{@path}" : 'detected'}"
      end

      protected
        def call_stack_messages
          @callers.unshift('N+1 Query method call stack').join( "\n  " )
        end
    end
  end
end
