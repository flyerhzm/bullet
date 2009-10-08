module Bullet
  class Counter
    class <<self
      include Bullet::Notification

      def start_request
      end

      def end_request
        clear
      end
      
      def clear
        @@klazz_associations = nil
        @@possible_objects = nil
        @@impossible_objects = nil
      end

      def need_counter_caches?
        !klazz_associations.empty?
      end

      def notification?
        need_counter_caches?
      end

      def notification_response
        response = []
        if need_counter_caches?
          response << counter_cache_messages.join("\n")
        end
        response
      end

      def console_title
        title = ["Need Counter Cache"]
      end

      def log_messages(path = nil)
        [counter_cache_messages(path)]
      end
      
      def add_counter_cache(object, associations)
        klazz = object.class
        if (!possible_objects[klazz].nil? and possible_objects[klazz].include?(object)) and
           (impossible_objects[klazz].nil? or !impossible_objects[klazz].include?(object))
          klazz_associations[klazz] ||= []
          klazz_associations[klazz] << associations
          unique(klazz_associations[klazz])
        end
      end

      def add_possible_objects(objects)
        klazz = objects.first.class
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
      
      private
        def counter_cache_messages(path = nil)
          messages = []
          klazz_associations.each do |klazz, associations|
            messages << [
              "Need Counter Cache",
              "  #{klazz} => [#{associations.map(&:inspect).join(', ')}]"
            ]
          end
          messages
        end
        
        def unique(array)
          array.flatten!
          array.uniq!
        end

        def call_stack_messages
          []
        end
        
        def klazz_associations
          @@klazz_associations ||= {}
        end

        def possible_objects
          @@possible_objects ||= {}
        end

        def impossible_objects
          @@impossible_objects ||= {}
        end
    end
  end
end
