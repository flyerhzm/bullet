module Bullet
  module Detector
    class NPlusOneQuery < Association
      # executed when object.assocations is called.
      # first, it keeps this method call for object.association.
      # then, it checks if this associations call is unpreload.
      #   if it is, keeps this unpreload associations and caller.
      def self.call_association(object, associations)
        @@checked = true
        add_call_object_associations(object, associations)

        if conditions_met?(object, associations)
          caller_in_project
          create_notification object.class, associations
        end
      end

      private
      def self.create_notification(klazz, associations)
        notice = Bullet::Notification::NPlusOneQuery.new( callers, klazz, associations )
        Bullet.notification_collector.add( notice )
      end

      # decide whether the object.associations is unpreloaded or not.
      def self.conditions_met?(object, associations)
        possible?(object) and 
        !impossible?(object) and 
        !association?(object, associations)
      end

      def self.caller_in_project
        vender_root ||= File.join(Rails.root, 'vendor')
        callers << caller.select { |c| c =~ /#{Rails.root}/ }.
                          reject { |c| c =~ /#{vender_root}/ }
        callers.uniq!
      end
    end
  end
end
