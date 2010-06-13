module Bullet
  module Notice
    class UnusedEagerLoading < Base
      def initialize( callers, base_klass, unused_associations, path = nil )
        super( nil, nil, nil, nil )
        @response = unused_preload_messages( base_klass, unused_associations, path )  
      end

      def unused_preload_messages(base_klass, unused_associations, path = nil)
        [
          "Unused Eager Loading #{path ? "in #{path}" : 'detected'}",
          klazz_associations_str(base_klass, unused_associations),
          "  Remove from your finder: #{associations_str(unused_associations)}"
        ]
      end

      def klazz_associations_str(klazz, associations)
        "  #{klazz} => [#{associations.map(&:inspect).join(', ')}]"
      end

      def associations_str(associations)
        ":include => #{associations.map{|a| a.to_sym unless a.is_a? Hash}.inspect}"
      end

    end
  end
end
