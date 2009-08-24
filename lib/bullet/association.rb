module Bullet
  class Association
    class <<self
      @@logger_file = File.open(Bullet::BulletLogger::LOG_FILE, 'a+')
      @@logger = Bullet::BulletLogger.new(@@logger_file)
      @@alert = true
      
      def start_request
        # puts "start request"
        @@object_associations ||= {}
        @@unpreload_associations ||= {}
        @@callers ||= []
        @@possible_objects ||= {}
        @@impossible_objects ||= {}
      end

      def end_request
        # puts "end request"
        @@object_associations = nil
        @@unpreload_associations = nil
        @@callers = nil
        @@possible_objects = nil
        @@impossible_objects = nil
      end

      def alert=(alert)
        @@alert = alert
      end

      def logger=(logger)
        if logger == false
          @@logger = nil
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
          str << @@unpreload_associations.to_a.collect{|klazz, associations| "model: #{klazz} => associations: [#{associations.join(', ')}]"}.join('\\n')
          str << "')"
          str << "</script>\n"
        end
        str
      end

      def log_unpreload_associations(path)
        if @@logger
          @@unpreload_associations.each do |klazz, associations| 
            @@logger.info "N+1 Query: PATH_INFO: #{path};    model: #{klazz} => associations: [#{associations.join(', ')}] \n Add to your finder: :include => #{associations.map{|a| a.to_sym}.inspect}"
          end  
          @@callers.each do |c|
            @@logger.info "N+1 Query: method call stack: \n" + c.join("\n")
          end
          @@logger_file.flush
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
      
      def add_impossible_object(object)
        # puts "add impossible object, #{object}"
        klazz = object.class
        @@impossible_objects[klazz] ||= []
        @@impossible_objects[klazz] << object
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
        @@impossible_objects ||= {}
        if (!@@possible_objects[klazz].nil? and @@possible_objects[klazz].include?(object)) and (@@impossible_objects[klazz].nil? or !@@impossible_objects[klazz].include?(object)) and (@@object_associations[object].nil? or !@@object_associations[object].include?(associations))
          @@unpreload_associations[klazz] ||= []
          @@unpreload_associations[klazz] << associations
          @@unpreload_associations[klazz].uniq!
          caller_in_project
        end
      end
      
      VENDOR_ROOT = File.join(RAILS_ROOT, 'vendor')
      def caller_in_project
        @@callers << caller.select {|c| c =~ /#{RAILS_ROOT}/}.reject {|c| c =~ /#{VENDOR_ROOT}/}
        @@callers.uniq!
      end
    end
  end
end
