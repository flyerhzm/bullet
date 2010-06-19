module Bullet
  module Registry
    class Object
      attr_reader :registry

      def initialize
        @registry = {}
      end

      def add( object_or_objects )
        klazz = object_or_objects.is_a?( Array ) ? object_or_objects.first.class :
                                                   object_or_objects.class
        @registry[klazz] ||= []
        @registry[klazz] << object_or_objects
        unique( @registry[klazz] )
      end

      def contains?( object )
        @registry[object.class] and @registry[object.class].include?( object )
      end

      private
      def unique( array )
        array.flatten!
        array.uniq!
      end
    end
  end
end
