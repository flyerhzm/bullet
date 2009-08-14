module Bullet
  class Association
    class <<self
      def start_request
        @@object_associations = {}
        @@unpreload_associations = {}
      end
      
      def unpreload_associations
        @@unpreload_associations
      end
      
      def has_klazz_association(klazz)
        !@@klazz_associations[klazz].nil? and @@klazz_associations.keys.include?(klazz)
      end
      
      def klazz_association(klazz)
        @@klazz_associations[klazz] || []
      end
      
      def define_association(klazz, associations)
        puts "define association: #{klazz} => #{associations}"
        @@klazz_associations ||= {}
        @@klazz_associations[klazz] ||= []
        @@klazz_associations[klazz] << associations
      end

      def add_association(object, associations)
        puts "add association: #{object} => #{associations}"
        @@object_associations[object] ||= []
        @@object_associations[object] << associations
      end

      def call_association(object, associations)
        puts "call assocation: #{object} => #{associations}"
        if @@object_associations[object].nil? or !@@object_associations[object].include?(associations)
          @@unpreload_associations[object.class] = associations
        end
      end

      def end_request
      end
    end
  end
end

ActiveRecord::ActiveRecordError # An ActiveRecord bug

module ActiveRecord
  module AssociationPreload
    module ClassMethods
      alias_method :origin_preload_associations, :preload_associations
      
      def preload_associations(records, associations, preload_options={})
        records = [records].flatten.compact.uniq
        return if records.empty?
        if records.count > 1
          records.each do |record|
            Bullet::Association.add_association(record, associations)
          end
        end
        origin_preload_associations(records, associations, preload_options={})
      end
    end
  end
  
  module Associations
    module ClassMethods
      alias_method :origin_collection_reader_method, :collection_reader_method
      
      def collection_reader_method(reflection, association_proxy_class)
        origin_collection_reader_method(reflection, association_proxy_class)
        Bullet::Association.define_association(self, reflection.name)
      end
    end
    
    class AssociationCollection
      alias_method :origin_load_target, :load_target
      
      def load_target
        origin_load_target
        Bullet::Association.call_association(@owner, @reflection.name)
      end
    end
  end
end