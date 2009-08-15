module Bullet
  class Association
    class <<self
      def start_request
        @@object_associations ||= {}
        @@unpreload_associations ||= {}
        @@possible_objects ||= {}
      end

      def end_request
        @@object_associations = nil
        @@unpreload_associations = nil
        @@possible_objects = nil
      end
      
      def unpreload_associations
        @@unpreload_associations
      end

      def has_unpreload_associations?
        !@@unpreload_associations.empty?
      end

      def unpreload_associations_str
        @@unpreload_associations.to_a.collect{|klazz, associations| "model: #{klazz} => assocations: #{associations}"}.join('\\n')
      end
      
      def has_klazz_association(klazz)
        !@@klazz_associations[klazz].nil? and @@klazz_associations.keys.include?(klazz)
      end
      
      def klazz_association(klazz)
        @@klazz_associations[klazz] || []
      end
      
      def define_association(klazz, associations)
        @@klazz_associations ||= {}
        @@klazz_associations[klazz] ||= []
        @@klazz_associations[klazz] << associations
      end

      def add_possible_objects(objects)
        klazz= objects.first.class
        @@possible_objects[klazz] ||= []
        @@possible_objects[klazz] << objects
        @@possible_objects[klazz].flatten!.uniq!
      end

      def add_association(object, associations)
        @@object_associations[object] ||= []
        @@object_associations[object] << associations
      end

      def call_association(object, associations)
        klazz = object.class
        if !@@possible_objects[klazz].nil? and@@possible_objects[klazz].include?(object) and (@@object_associations[object].nil? or !@@object_associations[object].include?(associations))
          @@unpreload_associations[klazz] = associations
        end
      end
    end
  end
end

ActiveRecord::ActiveRecordError # An ActiveRecord bug

module ActiveRecord
  class Base
    class <<self
      alias_method :origin_find_every, :find_every
      
      def find_every(options)
        records = origin_find_every(options)

        if records and records.size > 1
          Bullet::Association.add_possible_objects(records)
        end

        records
      end
    end
  end

  module AssociationPreload
    module ClassMethods
      alias_method :origin_preload_associations, :preload_associations
      
      def preload_associations(records, associations, preload_options={})
        records = [records].flatten.compact.uniq
        return if records.empty?
        records.each do |record|
          Bullet::Association.add_association(record, associations)
        end
        origin_preload_associations(records, associations, preload_options={})
      end
    end
  end
  
  module Associations
    module ClassMethods
      alias_method :origin_collection_reader_method, :collection_reader_method
      
      def collection_reader_method(reflection, association_proxy_class)
        Bullet::Association.define_association(self, reflection.name)
        origin_collection_reader_method(reflection, association_proxy_class)
      end
    end
    
    class AssociationCollection
      alias_method :origin_load_target, :load_target

      def load_target
        Bullet::Association.call_association(@owner, @reflection.name)
        origin_load_target
      end  
    end
  end
end
