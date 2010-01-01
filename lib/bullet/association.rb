module Bullet
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
        @@unpreload_associations = nil
        @@unused_preload_associations = nil
        @@callers = nil
        @@possible_objects = nil
        @@impossible_objects = nil
        @@call_object_associations = nil
        @@eager_loadings = nil
      end

      def notification?
        check_unused_preload_associations unless @@checked
        has_unpreload_associations? or has_unused_preload_associations?
      end

      def add_unpreload_associations(klazz, associations)
        unpreload_associations[klazz] ||= []
        unpreload_associations[klazz] << associations
        unique(unpreload_associations[klazz])
      end

      def add_unused_preload_associations(klazz, associations)
        unused_preload_associations[klazz] ||= []
        unused_preload_associations[klazz] << associations
        unique(unused_preload_associations[klazz])
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

      def has_unused_preload_associations?
        !unused_preload_associations.empty?
      end

      def has_unpreload_associations?
        !unpreload_associations.empty?
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

        def notification_response
          response = []
          if has_unused_preload_associations?
            response << unused_preload_messages.join("\n")
          end
          if has_unpreload_associations?
            response << unpreload_messages.join("\n")
          end
          response
        end

        def console_title
          title = []
          title << unused_preload_messages.first.first unless unused_preload_messages.empty?
          title << unpreload_messages.first.first unless unpreload_messages.empty?
          title
        end

        def log_messages(path = nil)
          messages = []
          messages << unused_preload_messages(path)
          messages << unpreload_messages(path)
          messages << call_stack_messages
          messages
        end

        def unused_preload_messages(path = nil)
          messages = []
          unused_preload_associations.each do |klazz, associations|
            messages << [
              "Unused Eager Loading #{path ? "in #{path}" : 'detected'}",
              klazz_associations_str(klazz, associations),
              "  Remove from your finder: #{associations_str(associations)}"
            ]
          end
          messages
        end

        def unpreload_messages(path = nil)
          messages = []
          unpreload_associations.each do |klazz, associations|
            messages << [
              "N+1 Query #{path ? "in #{path}" : 'detected'}",
              klazz_associations_str(klazz, associations),
              "  Add to your finder: #{associations_str(associations)}"
            ]
          end
          messages
        end

        def call_stack_messages
          callers.inject([]) do |messages, c|
            messages << ['N+1 Query method call stack', c.collect {|line| "  #{line}"}].flatten
          end
        end

        def klazz_associations_str(klazz, associations)
          "  #{klazz} => [#{associations.map(&:inspect).join(', ')}]"
        end

        def associations_str(associations)
          ":include => #{associations.map{|a| a.to_sym unless a.is_a? Hash}.inspect}"
        end
        
        def unique(array)
          array.flatten!
          array.uniq!
        end

        # unpreload_associations keep the class relationships 
        # that the associations, belongs to the class, are used but not preloaded.
        # e.g. { Post => [:comments] }
        # so the unpreload_associations should be preloaded by find :include.
        def unpreload_associations
          @@unpreload_associations ||= {}
        end
        
        # unused_preload_associations keep the class relationships 
        # that the associations, belongs to the class, are preloaded but not used.
        # e.g. { Post => [:comments] }
        # so the unused_preload_associations should be removed from find :include.
        def unused_preload_associations
          @@unused_preload_associations ||= {}
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
