module Bullet
  module Detector
    class UnusedEagerAssociation < Association
        def add_unused_preload_associations(klazz, associations)
          notice = Bullet::Notice::UnusedEagerLoading.new( callers, klazz, associations )
          Bullet.add_notification( notice )
        end

        # check if there are unused preload associations.
        # for each object => association
        #   get related_objects from eager_loadings associated with object and associations
        #   get call_object_association from associations of call_object_associations whose object is in related_objects 
        #   if association not in call_object_association, then the object => association - call_object_association is ununsed preload assocations
        def check_unused_preload_associations
          @@checked = true
          object_associations.each do |object, association|
            related_objects = eager_loadings.select {|key, value| key.include?(object) and value == association}.collect(&:first).flatten

            call_object_association = related_objects.collect { |related_object| call_object_associations[related_object] }.compact.flatten.uniq

            diff_object_association = (association - call_object_association).reject {|a| a.is_a? Hash}

            add_unused_preload_associations(object.class, diff_object_association) unless diff_object_association.empty?

          end
        end

    end
  end
end
