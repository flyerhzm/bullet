module Bullet
  module Detector
    class Association
      class <<self
        include Bullet::Notification

        def start_request
          @@checked = false
        end

        def end_request
          clear
        end
        
        def clear
          @@object_associations = nil
          @@callers = nil
          @@possible_objects = nil
          @@impossible_objects = nil
          @@call_object_associations = nil
          @@eager_loadings = nil
        end

        def add_unpreload_associations(klazz, associations)
          notice = Bullet::Notice::NPlusOneQuery.new( callers, klazz, associations )
          Bullet.add_notification( notice )
        end

        def add_unused_preload_associations(klazz, associations)
          notice = Bullet::Notice::UnusedEagerLoading.new( callers, klazz, associations )
          Bullet.add_notification( notice )
        end

        def add_object_associations(object, associations)
          object_associations[object] ||= []
          object_associations[object] << associations
          unique(object_associations[object])
        end

        def add_call_object_associations(object, associations)
          call_object_associations[object] ||= []
          call_object_associations[object] << associations
          unique(call_object_associations[object])
        end

        def add_possible_objects(objects)
          klazz = objects.is_a?(Array) ? objects.first.class : objects.class
          possible_objects[klazz] ||= []
          possible_objects[klazz] << objects
          unique(possible_objects[klazz])
        end

        def add_impossible_object(object)
          klazz = object.class
          impossible_objects[klazz] ||= []
          impossible_objects[klazz] << object
          impossible_objects[klazz].uniq!
        end

        def add_eager_loadings(objects, associations)
          objects = Array(objects)
          eager_loadings[objects] ||= []
          eager_loadings.each do |k, v|
            unless (k & objects).empty?
              if (k & objects) == k
                eager_loadings[k] << associations
                unique(eager_loadings[k])
                break
              else
                eager_loadings.merge!({(k & objects) => (eager_loadings[k].dup << associations)})
                unique(eager_loadings[(k & objects)])
                eager_loadings.merge!({(k - objects) => eager_loadings[k]}) unless (k - objects).empty?
                unique(eager_loadings[(k - objects)])
                eager_loadings.delete(k)
                objects = objects - k
              end
            end
          end
          unless objects.empty?
            eager_loadings[objects] << associations
            unique(eager_loadings[objects])
          end
        end

        # executed when object.assocations is called.
        # first, it keeps this method call for object.association.
        # then, it checks if this associations call is unpreload.
        #   if it is, keeps this unpreload associations and caller.
        def call_association(object, associations)
          add_call_object_associations(object, associations)
          if unpreload_associations?(object, associations)
            add_unpreload_associations(object.class, associations)
            caller_in_project
          end
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

        private
          # decide whether the object.associations is unpreloaded or not.
          def unpreload_associations?(object, associations)
            possible?(object) and !impossible?(object) and !association?(object, associations)
          end

          def possible?(object)
            klazz = object.class
            possible_objects[klazz] and possible_objects[klazz].include?(object)
          end

          def impossible?(object)
            klazz = object.class
            impossible_objects[klazz] and impossible_objects[klazz].include?(object)
          end

          # check if object => associations already exists in object_associations.
          def association?(object, associations)
            object_associations.each do |key, value|
              if key == object
                value.each do |v|
                  result = v.is_a?(Hash) ? v.has_key?(associations) : v == associations
                  return true if result
                end
              end
            end
            return false
          end

          def unique(array)
            array.flatten!
            array.uniq!
          end

          # object_associations keep the object relationships 
          # that the object has many associations.
          # e.g. { <Post id:1> => [:comments] }
          # the object_associations keep all associations that may be or may no be 
          # unpreload associations or unused preload associations.
          def object_associations
            @@object_associations ||= {}
          end

          # call_object_assciations keep the object relationships
          # that object.associations is called.
          # e.g. { <Post id:1> => [:comments] }
          # they are used to detect unused preload associations.
          def call_object_associations
            @@call_object_associations ||= {}
          end

          # possible_objects keep the class to object relationships
          # that the objects may cause N+1 query.
          # e.g. { Post => [<Post id:1>, <Post id:2>] }
          def possible_objects
            @@possible_objects ||= {}
          end

          # impossible_objects keep the class to objects relationships
          # that the objects may not cause N+1 query.
          # e.g. { Post => [<Post id:1>, <Post id:2>] }
          # Notice: impossible_objects are not accurate,
          # if find collection returns only one object, then the object is impossible object,
          # impossible_objects are used to avoid treating 1+1 query to N+1 query.
          def impossible_objects
            @@impossible_objects ||= {}
          end

          # eager_loadings keep the object relationships
          # that the associations are preloaded by find :include.
          # e.g. { [<Post id:1>, <Post id:2>] => [:comments, :user] }
          def eager_loadings
            @@eager_loadings ||= {}
          end

          def caller_in_project
            vender_root ||= File.join(Rails.root, 'vendor')
            callers << caller.select {|c| c =~ /#{Rails.root}/}.reject {|c| c =~ /#{vender_root}/}
            callers.uniq!
          end

          def callers
            @@callers ||= []
          end
      end
    end
  end
end
