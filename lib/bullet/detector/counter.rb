module Bullet
  module Detector
    class Counter < Base
      def self.clear
        @@possible_objects = nil
        @@impossible_objects = nil
      end

      def self.add_counter_cache(object, associations)
        if conditions_met?( object, associations )
          create_notification object.class, associations
        end
      end

      def self.add_possible_objects(objects)
        klazz = objects.first.class
        possible_objects[klazz] ||= []
        possible_objects[klazz] << objects
        unique(possible_objects[klazz])
      end

      def self.add_impossible_object(object)
        klazz = object.class
        impossible_objects[klazz] ||= []
        impossible_objects[klazz] << object
        impossible_objects[klazz].uniq!
      end
      
      private
      def self.create_notification( klazz, associations )
         notice = Bullet::Notification::CounterCache.new klazz, associations
         Bullet.add_notification notice
      end

      def self.unique(array)
        array.flatten!
        array.uniq!
      end

      def self.possible_objects
        @@possible_objects ||= {}
      end

      def self.impossible_objects
        @@impossible_objects ||= {}
      end

      def self.conditions_met?( object, associations )
        object_in_possible_objects?( object ) and
        object_not_in_impossible_objects?( object )
      end

      def self.object_in_possible_objects?( object )
        !possible_objects[ object.class ].nil? and 
        possible_objects[ object.class ].include?( object )
      end

      def self.object_not_in_impossible_objects?( object )
        impossible_objects[ object.class ].nil? or
        !impossible_objects[ object.class ].include?( object )
      end
    end
  end
end
