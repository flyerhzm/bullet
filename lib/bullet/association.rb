module Bullet
  class Association
    class <<self
      @@logger_file = File.open(Bullet::BulletLogger::LOG_FILE, 'a+')
      @@logger = Bullet::BulletLogger.new(@@logger_file)
      @@alert = true
      
      def start_request
        puts "start request"
      end

      def end_request
        puts "end request"
        @@object_associations = nil
        @@unpreload_associations = nil
        @@unused_preload_associations = nil
        @@callers = nil
        @@possible_objects = nil
        @@impossible_objects = nil
        @@call_object_associations = nil
      end

      def alert=(alert)
        @@alert = alert
      end

      def logger=(logger)
        if logger == false
          @@logger = nil
        end
      end
      
      def check_unused_preload_associations
        object_associations.each do |object, association|
          call_association = call_object_associations[object] || []
          association.uniq! unless association.flatten!.nil?
          call_association.uniq! unless call_association.flatten!.nil?
          
          add_unused_preload_associations(object.class, association - call_association) unless (association - call_association).empty?
        end
      end
      
      def has_bad_assocations?
        check_unused_preload_associations
        has_unpreload_associations? or has_unused_preload_associations?
      end

      def has_unused_preload_associations?
        !unused_preload_associations.empty?
      end
      
      def has_unpreload_associations?
        !unpreload_associations.empty?
      end

      def bad_associations_alert
        str = ''
        if @@alert
          str = "<script type='text/javascript'>"
          str << "alert('The request has unused preload assocations as follows:\\n"
          str << (has_unused_preload_associations? ? bad_associations_str(unused_preload_associations) : "None")
          str << "\\nThe request has N+1 queries as follows:\\n"
          str << (has_unpreload_associations? ? bad_associations_str(unpreload_associations) : "None")
          str << "')"
          str << "</script>\n"
        end
        str
      end

      def log_bad_associations(path)
        if @@logger
          unused_preload_associations.each do |klazz, associations|
            @@logger.info "Unused preload associations: PATH_INFO: #{path};    " + klazz_associations_str(klazz, associations) + "\n Remove from your finder: " + associations_str(associations)
          end
          unpreload_associations.each do |klazz, associations| 
            @@logger.info "N+1 Query: PATH_INFO: #{path};    " + klazz_associations_str(klazz, associations) + "\n Add to your finder: " + associations_str(associations)
          end  
          callers.each do |c|
            @@logger.info "N+1 Query: method call stack: \n" + c.join("\n")
          end
          @@logger_file.flush
        end
      end
      
      def bad_associations_str(bad_associations)
        puts bad_associations.inspect
        bad_associations.to_a.collect{|klazz, associations| klazz_associations_str(klazz, associations)}.join('\\n')
      end
      
      def klazz_associations_str(klazz, associations)
        "model: #{klazz} => associations: [#{associations.join(', ')}]"
      end
      
      def associations_str(associations)
        ":include => #{associations.map{|a| a.to_sym unless a.is_a? Hash}.inspect}"
      end

      def has_klazz_association(klazz)
        !klazz_associations[klazz].nil? and klazz_associations.keys.include?(klazz)
      end
      
      def define_association(klazz, associations)
        puts "define association, #{klazz} => #{associations}"
        add_klazz_associations(klazz, associations)
      end

      def call_association(object, associations)
        puts "call association, #{object} => #{associations}"
        if unpreload_associations?(object, associations)
          add_unpreload_associations(object.class, associations)
          add_call_object_associations(object, associations)
          caller_in_project
        end
      end
      
      def unpreload_associations?(object, associations)
        klazz = object.class
        (!possible_objects[klazz].nil? and possible_objects[klazz].include?(object)) and 
        (impossible_objects[klazz].nil? or !impossible_objects[klazz].include?(object)) and 
        (object_associations[object].nil? or !object_associations[object].include?(associations))
      end

      def add_unpreload_associations(klazz, associations)
        puts "add unpreload associations, #{klazz} => #{associations.inspect}"
        unpreload_associations[klazz] ||= []
        unpreload_associations[klazz] << associations
        unpreload_associations[klazz].uniq!
      end
      
      def add_unused_preload_associations(klazz, associations)
        puts "add unused preload associations, #{klazz} => #{associations.inspect}"
        unused_preload_associations[klazz] ||= []
        unused_preload_associations[klazz] << associations
        unused_preload_associations[klazz].flatten!.uniq!
      end

      def add_association(object, associations)
        puts "add associations, #{object} => #{associations.inspect}"
        object_associations[object] ||= []
        object_associations[object] << associations
      end

      def add_call_object_associations(object, associations)
        puts "add call object associations, #{object} => #{associations.inspect}"
        call_object_associations[object] ||= []
        call_object_associations[object] << associations
      end

      def add_possible_objects(objects)
        puts "add possible objects, #{objects.inspect}"
        klazz= objects.first.class
        possible_objects[klazz] ||= []
        possible_objects[klazz] << objects
        possible_objects[klazz].flatten!.uniq!
      end

      def add_impossible_object(object)
        puts "add impossible object, #{object}"
        klazz = object.class
        impossible_objects[klazz] ||= []
        impossible_objects[klazz] << object
      end
      
      def add_klazz_associations(klazz, associations)
        puts "define associations, #{klazz} => #{associations.inspect}"
        klazz_associations[klazz] ||= []
        klazz_associations[klazz] << associations
      end
      
      def unpreload_associations
        @@unpreload_associations ||= {}
      end
      
      def unused_preload_associations
        @@unused_preload_associations ||= {}
      end
      
      def object_associations
        @@object_associations ||= {}
      end
      
      def call_object_associations
        @@call_object_associations ||= {}
      end
      
      def possible_objects
        @@possible_objects ||= {}
      end

      def impossible_objects
        @@impossible_objects ||= {}
      end
      
      def klazz_associations
        @@klazz_associations ||= {}
      end
      
      VENDOR_ROOT = File.join(RAILS_ROOT, 'vendor')
      def caller_in_project
        callers << caller.select {|c| c =~ /#{RAILS_ROOT}/}.reject {|c| c =~ /#{VENDOR_ROOT}/}
        callers.uniq!
      end
      
      def callers
        @@callers ||= []
      end
    end
  end
end
