module Bullet
  module Detector
    class NPlusOneQuery < Association
      extend Dependency

      class <<self
        # executed when object.assocations is called.
        # first, it keeps this method call for object.association.
        # then, it checks if this associations call is unpreload.
        #   if it is, keeps this unpreload associations and caller.
        def call_association(object, associations)
          return unless Bullet.start?
          return unless object.primary_key_value
          return if inversed_objects.include?(object.bullet_key, associations)
          add_call_object_associations(object, associations)

          Bullet.debug("Detector::NPlusOneQuery#call_association", "object: #{object.bullet_key}, associations: #{associations}")
          if conditions_met?(object.bullet_key, associations)
            Bullet.debug("detect n + 1 query", "object: #{object.bullet_key}, associations: #{associations}")
            create_notification caller_in_project, object.class.to_s, associations
          end
        end

        def add_possible_objects(object_or_objects)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?
          objects = Array(object_or_objects)
          return if objects.map(&:primary_key_value).compact.empty?

          Bullet.debug("Detector::NPlusOneQuery#add_possible_objects", "objects: #{objects.map(&:bullet_key).join(', ')}")
          objects.each { |object| possible_objects.add object.bullet_key }
        end

        def add_impossible_object(object)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?
          return unless object.primary_key_value

          Bullet.debug("Detector::NPlusOneQuery#add_impossible_object", "object: #{object.bullet_key}")
          impossible_objects.add object.bullet_key
        end

        def add_inversed_object(object, association)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?
          return unless object.primary_key_value

          Bullet.debug("Detector::NPlusOneQuery#add_inversed_object", "object: #{object.bullet_key}, association: #{association}")
          inversed_objects.add object.bullet_key, association
        end

        private
          def create_notification(callers, klazz, associations)
            notify_associations = Array(associations) - Bullet.get_whitelist_associations(:n_plus_one_query, klazz)

            if notify_associations.present?
              notice = Bullet::Notification::NPlusOneQuery.new(callers, klazz, notify_associations)
              Bullet.notification_collector.add(notice)
            end
          end

          # decide whether the object.associations is unpreloaded or not.
          def conditions_met?(bullet_key, associations)
            possible?(bullet_key) && !impossible?(bullet_key) && !association?(bullet_key, associations)
          end

          def caller_in_project
            app_root = rails? ? Rails.root.to_s : Dir.pwd
            vendor_root = app_root + "/vendor"
            caller.select do |c|
              c.include?(app_root) && !c.include?(vendor_root) ||
              Bullet.stacktrace_includes.any? { |include| c.include?(include) }
            end
          end

          def possible?(bullet_key)
            possible_objects.include? bullet_key
          end

          def impossible?(bullet_key)
            impossible_objects.include? bullet_key
          end

          # check if object => associations already exists in object_associations.
          def association?(bullet_key, associations)
            value = object_associations[bullet_key]
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
