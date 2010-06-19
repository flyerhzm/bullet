module Bullet
  module Detector
    class UnusedEagerAssociation < Association
      # check if there are unused preload associations.
      # for each object => association
      #   get related_objects from eager_loadings associated with object and associations
      #   get call_object_association from associations of call_object_associations whose object is in related_objects 
      #   if association not in call_object_association, then the object => association - call_object_association is ununsed preload assocations
      def self.check_unused_preload_associations
        @@checked = true
        object_associations.each do |object, association|
          object_association_diff = diff_object_association object, association
          next if object_association_diff.empty?

          create_notification object.class, object_association_diff
        end
      end
      
      protected
      def self.create_notification(klazz, associations)
        notice = Bullet::Notification::UnusedEagerLoading.new( klazz, associations )
        Bullet.add_notification( notice )
      end

      def self.related_objects( object, association )
        eager_loadings.select do |key, value| 
          key.include?(object) and value == association
        end.collect(&:first).flatten
      end
      
      def self.call_object_association( object, association )
        related_objects( object, association ).collect do |related_object| 
          call_object_associations[related_object] 
        end.compact.flatten.uniq
      end

      def self.diff_object_association( object, association )
        potential_objects = association - call_object_association( object, association )
        potential_objects.reject {|a| a.is_a?( Hash ) }
      end
    end
  end
end
