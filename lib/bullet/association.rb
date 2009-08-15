module Bullet
  class Association
    class <<self
      @@bullet_log = Bullet::BulletLogger.new(File.open(Bullet::BulletLogger::LOG_FILE, 'a+'))
      
      def start_request
        @@object_associations ||= {}
        @@unpreload_associations ||= {}
        @@possible_objects ||= {}
      end

      def end_request
        @@object_associations = nil
        @@unpreload_associations = nil
        @@possible_objects = nil
      end
      
      def unpreload_associations
        @@unpreload_associations
      end

      def has_unpreload_associations?
        !@@unpreload_associations.empty?
      end

      def unpreload_associations_str
        @@unpreload_associations.to_a.collect{|klazz, associations| "model: #{klazz} => assocations: #{associations}"}.join('\\n')
      end

      def log_unpreload_associations(path)
        @@unpreload_associations.each do |klazz, associations| 
          @@bullet_log.info "PATH_INFO: #{path}    model: #{klazz} => assocations: #{associations}"
        end
      end

      def has_klazz_association(klazz)
        !@@klazz_associations[klazz].nil? and @@klazz_associations.keys.include?(klazz)
      end
      
      def klazz_association(klazz)
        @@klazz_associations[klazz] || []
      end
      
      def define_association(klazz, associations)
        @@klazz_associations ||= {}
        @@klazz_associations[klazz] ||= []
        @@klazz_associations[klazz] << associations
      end

      def add_possible_objects(objects)
        klazz= objects.first.class
        @@possible_objects[klazz] ||= []
        @@possible_objects[klazz] << objects
        @@possible_objects[klazz].flatten!.uniq!
      end

      def add_association(object, associations)
        @@object_associations[object] ||= []
        @@object_associations[object] << associations
      end

      def call_association(object, associations)
        klazz = object.class
        if !@@possible_objects[klazz].nil? and@@possible_objects[klazz].include?(object) and (@@object_associations[object].nil? or !@@object_associations[object].include?(associations))
          @@unpreload_associations[klazz] = associations
        end
      end
    end
  end
end
