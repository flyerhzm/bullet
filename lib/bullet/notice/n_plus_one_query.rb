module Bullet
  module Notice
    class NPlusOneQuery < Base
      def initialize( callers, base_class, associations, path = nil )
        super( base_class, associations, path )

        @callers = callers
      end

      def body
        [ klazz_associations_str, 
          "  Add to your finder: #{associations_str}",
          call_stack_messages
        ].flatten.join( "\n" )
      end

      def title
        "N+1 Query #{@path ? "in #{@path}" : 'detected'}"
      end

      protected
      def call_stack_messages
        @callers.collect do |c|
          [ 'N+1 Query method call stack', 
            c.collect {|line| "  #{line}"} ].flatten
        end
      end

    end
  end
end
