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
    end
  end
end
