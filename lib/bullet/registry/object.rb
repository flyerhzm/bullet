module Bullet
  module Registry
    class Object < Base
      def add( object_or_objects )
        klazz = object_or_objects.is_a?( Array ) ? object_or_objects.first.class :
                                                   object_or_objects.class
        super( klazz, object_or_objects )
      end

      def contains?( object )
        @registry[object.class] and @registry[object.class].include?( object )
      end
    end
  end
end
