module Bullet
  module Detector
    class NPlusOneQuery < Association
      def self.add_unpreload_associations(klazz, associations)
        notice = Bullet::Notification::NPlusOneQuery.new( callers, klazz, associations )
        Bullet.add_notification( notice )
      end

      # executed when object.assocations is called.
      # first, it keeps this method call for object.association.
      # then, it checks if this associations call is unpreload.
      #   if it is, keeps this unpreload associations and caller.
      def self.call_association(object, associations)
        @@checked = true
        add_call_object_associations(object, associations)
        if unpreload_associations?(object, associations)
          caller_in_project
          add_unpreload_associations(object.class, associations)
        end
      end

      private
      # decide whether the object.associations is unpreloaded or not.
      def self.unpreload_associations?(object, associations)
        possible?(object) and !impossible?(object) and !association?(object, associations)
      end

      def self.caller_in_project
        vender_root ||= File.join(Rails.root, 'vendor')
        callers << caller.select {|c| c =~ /#{Rails.root}/}.reject {|c| c =~ /#{vender_root}/}
        callers.uniq!
      end
    end
  end
end
