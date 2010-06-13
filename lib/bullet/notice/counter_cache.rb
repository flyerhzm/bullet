module Bullet
  module Notice
    class CounterCache < Base
      def initialize( base_class, associations, path = nil )
        super( nil, nil, nil, nil )

        @base_class = base_class
        @associations = associations
        @path = path

        @response = counter_cache_messages
      end

      def body
        klass_associations_str
      end

      def title
        "Need Counter Cache"
      end
    end
  end
end
