module Bullet
  module Detector
    class Counter < Base
      class <<self
        def clear
          @@possible_objects = nil
          @@impossible_objects = nil
        end

        def add_counter_cache(object, associations)
          if conditions_met?(object.bullet_ar_key, associations)
            create_notification object.class.to_s, associations
          end
        end

        def add_possible_objects(object_or_objects)
          if object_or_objects.is_a? Array
            object_or_objects.each { |object| possible_objects.add object.bullet_ar_key }
          else
            possible_objects.add object_or_objects.bullet_ar_key
          end
        end

        def add_impossible_object(object)
          impossible_objects.add object.bullet_ar_key
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

          def conditions_met?(bullet_ar_key, associations)
            possible_objects.include?(bullet_ar_key) && !impossible_objects.include?(bullet_ar_key)
          end
      end
    end
  end
end
