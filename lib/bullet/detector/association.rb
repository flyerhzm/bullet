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
          @@possible_objects = nil
          @@impossible_objects = nil
          @@call_object_associations = nil
          @@eager_loadings = nil
        end

        def add_object_associations(object, associations)
          return if !Bullet.n_plus_one_query_enable? && !Bullet.unused_eager_loading_enable?
          object_associations.add(object.bullet_ar_key, associations) if object.id
        end

        def add_call_object_associations(object, associations)
          return if !Bullet.n_plus_one_query_enable? && !Bullet.unused_eager_loading_enable?
          call_object_associations.add(object.bullet_ar_key, associations) if object.id
        end

        private
          # object_associations keep the object relationships
          # that the object has many associations.
          # e.g. { "Post:1" => [:comments] }
          # the object_associations keep all associations that may be or may no be
          # unpreload associations or unused preload associations.
          def object_associations
            @@object_associations ||= Bullet::Registry::Base.new
          end

          # call_object_assciations keep the object relationships
          # that object.associations is called.
          # e.g. { "Post:1" => [:comments] }
          # they are used to detect unused preload associations.
          def call_object_associations
            @@call_object_associations ||= Bullet::Registry::Base.new
          end

          # possible_objects keep the class to object relationships
          # that the objects may cause N+1 query.
          # e.g. { Post => ["Post:1", "Post:2"] }
          def possible_objects
            @@possible_objects ||= Bullet::Registry::Object.new
          end

          # impossible_objects keep the class to objects relationships
          # that the objects may not cause N+1 query.
          # e.g. { Post => ["Post:1", "Post:2"] }
          # Notice: impossible_objects are not accurate,
          # if find collection returns only one object, then the object is impossible object,
          # impossible_objects are used to avoid treating 1+1 query to N+1 query.
          def impossible_objects
            @@impossible_objects ||= Bullet::Registry::Object.new
          end

          # eager_loadings keep the object relationships
          # that the associations are preloaded by find :include.
          # e.g. { ["Post:1", "Post:2"] => [:comments, :user] }
          def eager_loadings
            @@eager_loadings ||= Bullet::Registry::Association.new
          end
      end
    end
  end
end
