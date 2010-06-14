module Bullet
  module Detector
    class Counter < Base
      def self.clear
        @@possible_objects = nil
        @@impossible_objects = nil
      end

      def self.add_counter_cache(object, associations)
        klazz = object.class
        if (!possible_objects[klazz].nil? and possible_objects[klazz].include?(object)) and
           (impossible_objects[klazz].nil? or !impossible_objects[klazz].include?(object))
           notice = Bullet::Notification::CounterCache.new klazz, associations
           Bullet.add_notification notice
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
    end
  end
end
