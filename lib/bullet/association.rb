module Bullet
  class Association
    class <<self
      include Bullet::Notification

      def start_request
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
        @@klazz_associations = nil
      end

      def notification?
        check_unused_preload_associations
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

      def add_klazz_associations(klazz, associations)
        klazz_associations[klazz] ||= []
        klazz_associations[klazz] << associations
        unique(klazz_associations[klazz])
      end

      def add_eager_loadings(objects, associations)
        objects = Array(objects)
        eager_loadings[objects] ||= []
        eager_loadings.each do |k, v|
          unless (k & objects).empty?
            if (k & objects) == k
              eager_loadings[k] = (eager_loadings[k] + Array(associations))
              unique(eager_loadings[k])
              break
            else
              eager_loadings.merge!({(k & objects) => (eager_loadings[k] + Array(associations))})
              unique(eager_loadings[(k & objects)])
              eager_loadings.merge!({(k - objects) => eager_loadings[k]}) unless (k - objects).empty?
              unique(eager_loadings[(k - objects)])
              eager_loadings.delete(k)
              objects = objects - k
            end
          end
        end
        unless objects.empty?
          eager_loadings[objects] << Array(associations) 
          unique(eager_loadings[objects])
        end
      end

      def define_association(klazz, associations)
        add_klazz_associations(klazz, associations)
      end

      def call_association(object, associations)
        add_call_object_associations(object, associations)
        if unpreload_associations?(object, associations)
          add_unpreload_associations(object.class, associations)
          caller_in_project
        end
      end

      def check_unused_preload_associations
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
