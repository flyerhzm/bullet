module Bullet
  class << self
    def collected_notifications_of_class(notification_class)
      Bullet.notification_collector.collection.select do |notification|
        notification.is_a? notification_class
      end
    end

    def collected_counter_cache_notifications
      collected_notifications_of_class Bullet::Notification::CounterCache
    end

    def collected_n_plus_one_query_notifications
      collected_notifications_of_class Bullet::Notification::NPlusOneQuery
    end

    def collected_unused_eager_association_notifications
      collected_notifications_of_class Bullet::Notification::UnusedEagerLoading
    end
  end

  module Detector
    class Association
      class <<self
        # returns true if all associations are preloaded
        def completely_preloading_associations?
          Bullet.collected_n_plus_one_query_notifications.empty?
        end

        # returns true if no unused preload associations
        def has_unused_preload_associations?
          Bullet.collected_unused_eager_association_notifications.present?
        end

        # returns true if a given object has a specific association
        def creating_object_association_for?(object, association)
          object_associations[object].present? && object_associations[object].include?(association)
        end

        # returns true if a given class includes the specific unpreloaded association
        def detecting_unpreload_association_for?(klass, association)
          for_class_and_assoc = Bullet.collected_n_plus_one_query_notifications.select do |notification|
            notification.base_class == klass and
            notification.associations.include?(association)
          end
          for_class_and_assoc.present?
        end

        # returns true if the given class includes the specific unused preloaded association
        def unused_preload_association_for?(klass, association)
          for_class_and_assoc = Bullet.collected_unused_eager_association_notifications.select do |notification|
            notification.base_class == klass and
            notification.associations.include?(association)
          end
          for_class_and_assoc.present?
        end
      end
    end
  end
end
