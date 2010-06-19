module Bullet
  module Registry
    class Association < Base
      def merge( base, associations )
        @registry.merge!( { base => associations } )
        unique( @registry[base] )
      end

      def similarly_associated( base, associations )
        @registry.select do |key, value|
          key.include?( base ) and value == associations
        end.collect( &:first ).flatten!
      end

      def [](base)
        @registry[base]
      end

      def delete( base )
        @registry.delete( base )
      end

      def select( *args, &block )
        @registry.select( *args, &block )
      end

      def each( &block ) 
        @registry.each( &block )
      end
    end
  end
end
