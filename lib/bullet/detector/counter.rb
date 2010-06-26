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
        possible_objects.add objects
      end

      def self.add_impossible_object(object)
        impossible_objects.add object
      end
      
      private
      def self.create_notification( klazz, associations )
         notice = Bullet::Notification::CounterCache.new klazz, associations
         Bullet.notification_collector.add notice
      end

      def self.possible_objects
        @@possible_objects ||= Bullet::Registry::Object.new
      end

      def self.impossible_objects
        @@impossible_objects ||= Bullet::Registry::Object.new
      end

      def self.conditions_met?( object, associations )
        possible_objects.contains?( object ) and
        !impossible_objects.contains?( object )
      end
    end
  end
end
