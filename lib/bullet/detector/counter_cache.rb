module Bullet
  module Detector
    class CounterCache < Base
      class <<self
        def clear
          @@possible_objects = nil
          @@impossible_objects = nil
        end

        def add_counter_cache(object, associations)
          return unless Bullet.counter_cache_enable?

          if conditions_met?(object.bullet_ar_key, associations)
            create_notification object.class.to_s, associations
          end
        end

        def add_possible_objects(object_or_objects)
          return unless Bullet.counter_cache_enable?

          if object_or_objects.is_a? Array
            object_or_objects.each { |object| possible_objects.add object.bullet_ar_key }
          else
            possible_objects.add object_or_objects.bullet_ar_key
          end
        end

        def add_impossible_object(object)
          return unless Bullet.counter_cache_enable?

          impossible_objects.add object.bullet_ar_key
        end

        private
          def create_notification(klazz, associations)
            notify_associations = Array(associations) - Bullet.get_whitelist_associations(:counter_cache, klazz)

            if notify_associations.present?
              notice = Bullet::Notification::CounterCache.new klazz, notify_associations
              Bullet.notification_collector.add notice
            end
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
