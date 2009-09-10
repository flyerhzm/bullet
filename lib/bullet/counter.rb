module Bullet
  class Counter
    class <<self
      include Bullet::Notification

      def start_request
      end

      def end_request
        @@klazz_associations = nil
      end

      def need_counter_caches?
        !klazz_associations.empty?
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

      def log_message(path = nil)
        counter_cache_messages(path)
      end
      
      def add_counter_cache(object, associations)
        klazz = object.class
        klazz_associations[klazz] ||= []
        klazz_associations[klazz] << associations
        klazz_associations[klazz].flatten!
        klazz_associations[klazz].uniq!
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
        end

        def call_stack_messages
          []
        end
        
        def klazz_associations
          @@klazz_associations ||= {}
        end
    end
  end
end
