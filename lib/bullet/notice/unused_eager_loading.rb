module Bullet
  module Notice
    class UnusedEagerLoading < Base
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
