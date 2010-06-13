module Bullet
  module Notice
    class NPlusOneQuery < Association
      def initialize( callers, base_class, associations, path = nil )
        super( nil, nil, nil, nil )
        @base_class = base_class
        @associations = associations
        @path = path

        @response = unpreload_messages
        @call_stack_messages = call_stack_messages( callers )
      end

      def unpreload_messages
        [
          "N+1 Query #{@path ? "in #{@path}" : 'detected'}",
          klazz_associations_str,
          "  Add to your finder: #{associations_str}"
        ]
      end

      def call_stack_messages( callers )
        callers.inject([]) do |messages, c|
          messages << [ 'N+1 Query method call stack', 
                        c.collect {|line| "  #{line}"} ].flatten
        end
      end

    end
  end
end
