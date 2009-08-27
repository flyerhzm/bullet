module Bullet
  class Association
    class <<self
      @@logger_file = File.open(Bullet::BulletLogger::LOG_FILE, 'a+')
      @@logger = Bullet::BulletLogger.new(@@logger_file)
      @@alert = true
      
      def start_request
        # puts "start request"
        @@object_associations ||= {}
        @@call_object_associations ||= {}
        @@unpreload_associations ||= {}
        @@unused_preload_associations ||= {}
        @@callers ||= []
        @@possible_objects ||= {}
        @@impossible_objects ||= {}
      end

      def end_request
        # puts "end request"
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
        @@object_associations.each do |object, association|
          call_association = @@call_object_associations[object] || []
          association.uniq! unless association.flatten!.nil?
          call_association.uniq! unless call_association.flatten!.nil?
          klazz = object.class
          unless (association - call_association).empty?
            @@unused_preload_associations[klazz] ||= []
            @@unused_preload_associations[klazz] << (association - call_association) 
            @@unused_preload_associations[klazz].flatten!.uniq!
          end
        end
      end
      
      def has_bad_assocations?
        check_unused_preload_associations
        has_unpreload_associations? or has_unused_preload_associations?
      end

      def has_unused_preload_associations?
        !@@unused_preload_associations.empty?
      end
      
      def has_unpreload_associations?
        !@@unpreload_associations.empty?
      end

      def bad_associations_alert
        str = ''
        if @@alert
          str = "<script type='text/javascript'>"
          str << "alert('The request has unused preload assocations as follows:\\n"
          str << (has_unused_preload_associations? ? @@unused_preload_associations.to_a.collect{|klazz, associations| "model: #{klazz} => associations: [#{associations.join(', ')}]"}.join('\\n') : "None")
          str << "\\nThe request has N+1 queries as follows:\\n"
          str << (has_unpreload_associations? ? @@unpreload_associations.to_a.collect{|klazz, associations| "model: #{klazz} => associations: [#{associations.join(', ')}]"}.join('\\n') : "None")
          str << "')"
          str << "</script>\n"
        end
        str
      end

      def log_bad_associations(path)
        if @@logger
          @@unused_preload_associations.each do |klazz, associations|
            @@logger.info "Unused preload associations: PATH_INFO: #{path};    model: #{klazz} => associations: [#{associations.join(', ')}] \n Remove from your finder: :include => #{associations.map{|a| a.to_sym}.inspect}"
          end
          @@unpreload_associations.each do |klazz, associations| 
            @@logger.info "N+1 Query: PATH_INFO: #{path};    model: #{klazz} => associations: [#{associations.join(', ')}] \n Add to your finder: :include => #{associations.map{|a| a.to_sym unless a.is_a? Hash}.inspect}"
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
          @@call_object_associations[object] ||= []
          @@call_object_associations[object] << associations
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
