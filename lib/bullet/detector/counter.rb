module Bullet
  module Detector
    class Counter < Base
      class <<self
        def clear
          @@possible_objects = nil
          @@impossible_objects = nil
        end

        def add_counter_cache(object, associations)
          if conditions_met?(object.ar_key, associations)
            create_notification object.class.to_s, associations
          end
        end

        def add_possible_objects(objects)
          possible_objects.add Array(objects).map(&:ar_key)
        end

        def add_impossible_object(object)
          impossible_objects.add object.ar_key
        end

        private
          def create_notification(klazz, associations)
             notice = Bullet::Notification::CounterCache.new klazz, associations
             Bullet.notification_collector.add notice
          end

          def possible_objects
            @@possible_objects ||= Bullet::Registry::Object.new
          end

          def impossible_objects
            @@impossible_objects ||= Bullet::Registry::Object.new
          end

          def conditions_met?(object_ar_key, associations)
            possible_objects.include?(object_ar_key) && !impossible_objects.include?(object_ar_key)
          end
      end
    end
  end
end
