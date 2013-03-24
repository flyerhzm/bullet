module Bullet
  module Detector
    class UnusedEagerLoading < Association
      class <<self
        # check if there are unused preload associations.
        #   get related_objects from eager_loadings associated with object and associations
        #   get call_object_association from associations of call_object_associations whose object is in related_objects
        #   if association not in call_object_association, then the object => association - call_object_association is ununsed preload assocations
        def check_unused_preload_associations
          return unless Bullet.unused_eager_loading_enable?

          @@checked = true
          object_associations.each do |bullet_ar_key, associations|
            object_association_diff = diff_object_associations bullet_ar_key, associations
            next if object_association_diff.empty?

            create_notification bullet_ar_key.bullet_class_name, object_association_diff
          end
        end

        def add_eager_loadings(objects, associations)
          return unless Bullet.unused_eager_loading_enable?
          bullet_ar_keys = objects.map(&:bullet_ar_key)

          to_add = nil
          to_merge, to_delete = [], []
          eager_loadings.each do |k, v|
            key_objects_overlap = k & bullet_ar_keys

            next if key_objects_overlap.empty?

            if key_objects_overlap == k
              to_add = [k, associations]
              break
            else
              to_merge << [key_objects_overlap, ( eager_loadings[k].dup  << associations )]

              keys_without_objects = k - bullet_ar_keys
              to_merge << [keys_without_objects, eager_loadings[k]]
              to_delete << k
              bullet_ar_keys = bullet_ar_keys - k
            end
          end

          eager_loadings.add *to_add if to_add
          to_merge.each { |k,val| eager_loadings.merge k, val }
          to_delete.each { |k| eager_loadings.delete k }

          eager_loadings.add bullet_ar_keys, associations unless bullet_ar_keys.empty?
        end

        private
          def create_notification(klazz, associations)
            notify_associations = Array(associations) - Bullet.get_whitelist_associations(:unused_eager_loading, klazz)

            if notify_associations.present?
              notice = Bullet::Notification::UnusedEagerLoading.new(klazz, notify_associations)
              Bullet.notification_collector.add(notice)
            end
          end

          def call_associations(bullet_ar_key, associations)
            all = Set.new
            eager_loadings.similarly_associated(bullet_ar_key, associations).each do |related_bullet_ar_key|
              coa = call_object_associations[related_bullet_ar_key]
              next if coa.nil?
              all.merge coa
            end
            all.to_a
          end

          def diff_object_associations(bullet_ar_key, associations)
            potential_associations = associations - call_associations(bullet_ar_key, associations)
            potential_associations.reject { |a| a.is_a?(Hash) }
          end
      end
    end
  end
end
