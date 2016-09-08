module Bullet
  module Notification
    class UnusedEagerLoading < Base
      def initialize(callers, base_class, associations, path = nil)
        super(base_class, associations, path)

        @callers = callers
      end

      def notification_data
        super.merge(
          :backtrace => @callers
        )
      end

      def body
        "#{klazz_associations_str}\n  Remove from your finder: #{associations_str}"
      end

      def title
        "Unused Eager Loading #{@path ? "in #{@path}" : 'detected'}"
      end
    end
  end
end
