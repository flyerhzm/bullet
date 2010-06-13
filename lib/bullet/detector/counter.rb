module Bullet
  module Detector
    class Counter
      class <<self
        include Bullet::Notification

        def start_request
        end

        def end_request
          clear
        end
        
        def clear
          @@possible_objects = nil
          @@impossible_objects = nil
        end

        def need_counter_caches?
          !klazz_associations.empty?
        end

        def add_counter_cache(object, associations)
          klazz = object.class
          if (!possible_objects[klazz].nil? and possible_objects[klazz].include?(object)) and
             (impossible_objects[klazz].nil? or !impossible_objects[klazz].include?(object))
             notice = Bullet::Notice::CounterCache.new klazz, associations
             Bullet.add_notification notice
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
          def unique(array)
            array.flatten!
            array.uniq!
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
end
