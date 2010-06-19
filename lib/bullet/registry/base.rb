module Bullet
  module Registry
    class Base
      attr_reader :registry

      def initialize
        @registry = {}
      end

      def [](key)
        @registry[key]
      end

      def add( key, value )
        @registry[key] ||= []
        @registry[key] << value
        unique( @registry[key] )
      end

      private
      def unique( array )
        array.flatten!
        array.uniq!
      end
    end
  end
end
