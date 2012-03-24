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

          if conditions_met?(object, associations)
            caller_in_project!
            create_notification object.class, associations
          end
        end

        private
          def create_notification(klazz, associations)
            notice = Bullet::Notification::NPlusOneQuery.new( callers, klazz, associations )
            Bullet.notification_collector.add( notice )
          end

          # decide whether the object.associations is unpreloaded or not.
          def conditions_met?(object, associations)
            possible?(object) && !impossible?(object) && !association?(object, associations)
          end

          def caller_in_project!
            vender_root ||= Rails.root.join('vendor').to_s
            callers << caller.select { |c| c.include?(Rails.root) }.
                              reject { |c| c.include?(vender_root) }
            callers.uniq!
          end

          def possible?(object)
            possible_objects.include? object
          end

          def impossible?(object)
            impossible_objects.include? object
          end

          # check if object => associations already exists in object_associations.
          def association?(object, associations)
            value = object_associations[object]
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
