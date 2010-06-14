module Bullet
  module Notice
    class NPlusOneQuery < Base
      def initialize( callers, base_class, associations, path = nil )
        super( base_class, associations, path )

        @callers = callers
      end

      def body
        "#{klazz_associations_str}\n  Add to your finder: #{associations_str}\n#{call_stack_messages}"
      end

      def title
        "N+1 Query #{@path ? "in #{@path}" : 'detected'}"
      end

      protected
      def call_stack_messages
        @callers.collect do |c|
          [ 'N+1 Query method call stack', 
            c.collect {|line| "  #{line}"} ].flatten
        end.join( "\n" )
      end

    end
  end
end
