module Bullet
  module Notice
    class UnusedEagerLoading < Base
      def initialize( callers, base_klass, unused_associations, path = nil )
        super( nil, nil, nil, nil )
        @base_class = base_class
        @associations = unused_associations
        @path = path

        @response = unused_preload_messages
      end

      def unused_preload_messages
        [
          "Unused Eager Loading #{@path ? "in #{@path}" : 'detected'}",
          klazz_associations_str,
          "  Remove from your finder: #{associations_str}"
        ]
      end

    end
  end
end
