module Bullet
  module Notice
    class UnusedEagerLoading < Base
      def initialize( callers, base_klass, unused_associations, path = nil )
        super( nil, nil, nil, nil )
        @base_class = base_class
        @associations = unused_associations
        @path = path
      end

      def body
        [
          klazz_associations_str,
          "  Remove from your finder: #{associations_str}"
        ].join( "\n" )
      end

      def title
        "Unused Eager Loading #{@path ? "in #{@path}" : 'detected'}" 
      end

    end
  end
end
