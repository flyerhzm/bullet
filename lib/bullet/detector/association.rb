module Bullet
  module Detector
    class Association < Base
      class <<self
        def start_request
          @@checked = false
        end

        def clear
          # Note that under ruby class variables are shared among the class
          # that declares them and all classes derived from that class.
          # The following variables are accessible by all classes that
          # derive from Bullet::Detector::Association - changing the variable
          # in one subclass will make the change visible to all subclasses!
          @@object_associations = nil
          @@callers = nil
          @@possible_objects = nil
          @@impossible_objects = nil
          @@call_object_associations = nil
          @@eager_loadings = nil
        end

        def add_object_associations(object, associations)
          object_associations.add( object, associations )
        end

        def add_call_object_associations(object, associations)
          call_object_associations.add( object, associations )
        end

        def add_possible_objects(objects)
          possible_objects.add objects
        end

        def add_impossible_object(object)
          impossible_objects.add object
        end

        def add_eager_loadings(objects, associations)
          objects = Array(objects)

          eager_loadings.each do |k, v|
            key_objects_overlap = k & objects

            next if key_objects_overlap.empty?

            if key_objects_overlap == k
              eager_loadings.add k, associations
              break

            else
              eager_loadings.merge key_objects_overlap, ( eager_loadings[k].dup  << associations )

              keys_without_objects = k - objects
              eager_loadings.merge keys_without_objects, eager_loadings[k] unless keys_without_objects.empty?

              eager_loadings.delete(k)
              objects = objects - k
            end
          end

          eager_loadings.add objects, associations unless objects.empty?
        end

        private
          def possible?(object)
            possible_objects.contains? object
          end

          def impossible?(object)
            impossible_objects.contains? object
          end

          # check if object => associations already exists in object_associations.
          def association?(object, associations)
            object_associations.each do |key, value|
              next unless key == object

              value.each do |v|
                result = v.is_a?(Hash) ? v.has_key?(associations) : v == associations
                return true if result
              end

            end
            return false
          end

          # object_associations keep the object relationships 
          # that the object has many associations.
          # e.g. { <Post id:1> => [:comments] }
          # the object_associations keep all associations that may be or may no be 
          # unpreload associations or unused preload associations.
          def object_associations
            @@object_associations ||= Bullet::Registry::Base.new
          end

          # call_object_assciations keep the object relationships
          # that object.associations is called.
          # e.g. { <Post id:1> => [:comments] }
          # they are used to detect unused preload associations.
          def call_object_associations
            @@call_object_associations ||= Bullet::Registry::Base.new
          end

          # possible_objects keep the class to object relationships
          # that the objects may cause N+1 query.
          # e.g. { Post => [<Post id:1>, <Post id:2>] }
          def possible_objects
            @@possible_objects ||= Bullet::Registry::Object.new
          end

          # impossible_objects keep the class to objects relationships
          # that the objects may not cause N+1 query.
          # e.g. { Post => [<Post id:1>, <Post id:2>] }
          # Notice: impossible_objects are not accurate,
          # if find collection returns only one object, then the object is impossible object,
          # impossible_objects are used to avoid treating 1+1 query to N+1 query.
          def impossible_objects
            @@impossible_objects ||= Bullet::Registry::Object.new
          end

          # eager_loadings keep the object relationships
          # that the associations are preloaded by find :include.
          # e.g. { [<Post id:1>, <Post id:2>] => [:comments, :user] }
          def eager_loadings
            @@eager_loadings ||= Bullet::Registry::Association.new
          end

          def callers
            @@callers ||= []
          end
      end
    end
  end
end
