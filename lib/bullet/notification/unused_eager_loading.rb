module Bullet
  module Notification
    class UnusedEagerLoading < Base
      def body
        "#{klazz_associations_str}\n  Remove from your finder: #{associations_str}"
      end

      def title
        "Unused Eager Loading #{@path ? "in #{@path}" : 'detected'}"
      end
    end
  end
end
