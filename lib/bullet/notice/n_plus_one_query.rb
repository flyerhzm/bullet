module Bullet
  module Notice
    class NPlusOneQuery < Base
      def initialize( callers, base_klass, associations, path = nil )
        super( nil, nil, nil, nil )
        @response = unpreload_messages( base_klass, associations, path )
        @call_stack_messages = call_stack_messages( callers )
      end

      def unpreload_messages(base_klass, associations, path = nil)
        [
          "N+1 Query #{path ? "in #{path}" : 'detected'}",
          klazz_associations_str(base_klass, associations),
          "  Add to your finder: #{associations_str(associations)}"
        ]
      end

      def call_stack_messages( callers )
        callers.inject([]) do |messages, c|
          messages << ['N+1 Query method call stack', c.collect {|line| "  #{line}"}].flatten
        end
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
