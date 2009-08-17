module Bullet
  class Association
    class <<self
      @@logger = Bullet::BulletLogger.new(File.open(Bullet::BulletLogger::LOG_FILE, 'a+'))
      @@alert = true
      
      def start_request
        # puts "start request"
        @@object_associations ||= {}
        @@unpreload_associations ||= {}
        @@possible_objects ||= {}
      end

      def end_request
        # puts "end request"
        @@object_associations = nil
        @@unpreload_associations = nil
        @@possible_objects = nil
      end

      def alert=(alert)
        @@alert = alert
      end

      def logger=(logger)
        if logger == false
          @@logger = nil
        elsif logger.is_a? Logger
          @@logger = logger
        end
      end
      
      def has_unpreload_associations?
        !@@unpreload_associations.empty?
      end

      def unpreload_associations_alert
        str = ''
        if @@alert
          str = "<script type='text/javascript'>"
          str << "alert('The request has N+1 queries as follows:\\n"
          str << @@unpreload_associations.to_a.collect{|klazz, associations| "model: #{klazz} => assocations: #{associations}"}.join('\\n')
          str << "')"
          str << "</script>\n"
        end
        str
      end

      def log_unpreload_associations(path)
        if @@logger
          @@unpreload_associations.each do |klazz, associations| 
            @@logger.info "PATH_INFO: #{path}    model: #{klazz} => assocations: #{associations}"
          end
        end
      end

      def has_klazz_association(klazz)
        !@@klazz_associations[klazz].nil? and @@klazz_associations.keys.include?(klazz)
      end
      
      def define_association(klazz, associations)
        # puts "define association, #{klazz} => #{associations}"
        @@klazz_associations ||= {}
        @@klazz_associations[klazz] ||= []
        @@klazz_associations[klazz] << associations
      end

      def add_possible_objects(objects)
        # puts "add possible object, #{objects}"
        klazz= objects.first.class
        @@possible_objects[klazz] ||= []
        @@possible_objects[klazz] << objects
        @@possible_objects[klazz].flatten!.uniq!
      end

      def add_association(object, associations)
        # puts "add association, #{object} => #{associations}"
        @@object_associations[object] ||= []
        @@object_associations[object] << associations
      end

      def call_association(object, associations)
        # puts "call association, #{object} => #{associations}"
        klazz = object.class
        @@possible_objects ||= {}
        if !@@possible_objects[klazz].nil? and @@possible_objects[klazz].include?(object) and (@@object_associations[object].nil? or !@@object_associations[object].include?(associations))
          @@unpreload_associations[klazz] = associations
        end
      end
    end
  end
end
