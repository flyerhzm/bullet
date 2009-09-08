module Bullet
  class Counter
    class <<self
      def start_request

      end

      def end_request
        @@klazz_associations = nil
      end

      def need_counter_caches?
        !klazz_associations.empty?
      end
      
      def add_counter_cache(object, associations)
        klazz = object.class
        klazz_associations[klazz] ||= []
        klazz_associations[klazz] << associations
        klazz_associations[klazz].flatten!
        klazz_associations[klazz].uniq!
      end
      
      def klazz_associations
        @@klazz_associations ||= {}
      end
    end
  end
end
