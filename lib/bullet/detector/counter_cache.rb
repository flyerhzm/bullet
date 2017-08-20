module Bullet
  module Detector
    class CounterCache < Base
      class <<self
        def add_counter_cache(object, associations)
          return unless Bullet.start?
          return unless Bullet.counter_cache_enable?
          return unless object.primary_key_value

          Bullet.debug('Detector::CounterCache#add_counter_cache', "object: #{object.bullet_key}, associations: #{associations}")
          if conditions_met?(object, associations)
            create_notification object.class.to_s, associations
          end
        end

        def add_possible_objects(object_or_objects)
          return unless Bullet.start?
          return unless Bullet.counter_cache_enable?
          objects = Array(object_or_objects)
          return if objects.map(&:primary_key_value).compact.empty?

          Bullet.debug('Detector::CounterCache#add_possible_objects', "objects: #{objects.map(&:bullet_key).join(', ')}")
          objects.each { |object| possible_objects.add object.bullet_key }
        end

        def add_impossible_object(object)
          return unless Bullet.start?
          return unless Bullet.counter_cache_enable?
          return unless object.primary_key_value

          Bullet.debug('Detector::CounterCache#add_impossible_object', "object: #{object.bullet_key}")
          impossible_objects.add object.bullet_key
        end

        def conditions_met?(object, associations)
          possible_objects.include?(object.bullet_key) && !impossible_objects.include?(object.bullet_key)
        end

        def possible_objects
          Thread.current[:bullet_counter_possible_objects]
        end

        def impossible_objects
          Thread.current[:bullet_counter_impossible_objects]
        end

        private

          def create_notification(klazz, associations)
            notify_associations = Array(associations) - Bullet.get_whitelist_associations(:counter_cache, klazz)

            if notify_associations.present?
              notice = Bullet::Notification::CounterCache.new klazz, notify_associations
              Bullet.notification_collector.add notice
            end
          end
      end
    end
  end
end
