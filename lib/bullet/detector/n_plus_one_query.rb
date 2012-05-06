module Bullet
  module Detector
    class NPlusOneQuery < Association
      class <<self
        # executed when object.assocations is called.
        # first, it keeps this method call for object.association.
        # then, it checks if this associations call is unpreload.
        #   if it is, keeps this unpreload associations and caller.
        def call_association(object, associations)
          @@checked = true
          add_call_object_associations(object, associations)

          if conditions_met?(object.bullet_ar_key, associations)
            create_notification caller_in_project, object.class.to_s, associations
          end
        end

        private
          def create_notification(callers, klazz, associations)
            notice = Bullet::Notification::NPlusOneQuery.new(callers, klazz, associations)
            Bullet.notification_collector.add(notice)
          end

          # decide whether the object.associations is unpreloaded or not.
          def conditions_met?(bullet_ar_key, associations)
            possible?(bullet_ar_key) && !impossible?(bullet_ar_key) && !association?(bullet_ar_key, associations)
          end

          def caller_in_project
            rails_root = Rails.root.to_s
            vendor_root = rails_root + "/vendor"
            caller.select { |c| c.include?(rails_root) && !c.include?(vendor_root) }
          end

          def possible?(bullet_ar_key)
            possible_objects.include? bullet_ar_key
          end

          def impossible?(bullet_ar_key)
            impossible_objects.include? bullet_ar_key
          end

          # check if object => associations already exists in object_associations.
          def association?(bullet_ar_key, associations)
            value = object_associations[bullet_ar_key]
            if value
              value.each do |v|
                result = v.is_a?(Hash) ? v.has_key?(associations) : v == associations
                return true if result
              end
            end

            return false
          end
      end
    end
  end
end
