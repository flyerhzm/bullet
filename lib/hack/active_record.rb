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
