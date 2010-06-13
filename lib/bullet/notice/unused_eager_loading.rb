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
        title + 
        [
          klazz_associations_str,
          "  Remove from your finder: #{associations_str}"
        ]
      end

      def title
        [ "Unused Eager Loading #{@path ? "in #{@path}" : 'detected'}" ]
      end

    end
  end
end
