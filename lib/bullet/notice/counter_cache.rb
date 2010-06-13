module Bullet
  module Notice
    class CounterCache < Base
      def initialize( base_class, associations, path = nil )
        super( nil, nil, nil, nil )

        @base_class = base_class
        @associations = associations
        @path = path

        @console_title = [ "Need Counter Cache" ]
        @response = counter_cache_messages
        @log_messages = counter_cache_messages
      end

      def counter_cache_messages
        [
          "Need Counter Cache",
          klass_associations_str
        ]
      end
    end
  end
end
