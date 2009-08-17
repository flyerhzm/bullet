if Bullet.enable?
  ActiveRecord::ActiveRecordError # An ActiveRecord bug

  module ActiveRecord
    class Base
      class <<self
        # if select a collection of objects, then these objects have possible to cause N+1 query
        # if select only one object, then the only one object has impossible to cause N+1 query
        alias_method :origin_find_every, :find_every
        
        def find_every(options)
          records = origin_find_every(options)

          if records 
            if records.size > 1
              Bullet::Association.add_possible_objects(records)
            elsif records.size == 1
              Bullet::Association.add_impossible_object(records.first)
            end
          end

          records
        end
      end
    end

    module AssociationPreload
      module ClassMethods
        # add include for one to many associations query
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
        # define one to many associations
        alias_method :origin_collection_reader_method, :collection_reader_method
        
        def collection_reader_method(reflection, association_proxy_class)
          Bullet::Association.define_association(self, reflection.name)
          origin_collection_reader_method(reflection, association_proxy_class)
        end
      end
      
      class AssociationCollection
        # call one to many associations
        alias_method :origin_load_target, :load_target

        def load_target
          Bullet::Association.call_association(@owner, @reflection.name)
          origin_load_target
        end  
      end

      class HasOneAssociation
        # call has_one association
        alias_method :origin_find_target, :find_target

        def find_target
          Bullet::Association.call_association(@owner, @reflection.name)
          origin_find_target
        end
      end

      class BelongsToAssociation
        # call belongs_to association
        alias_method :origin_find_target, :find_target

        def find_target
          Bullet::Association.call_association(@owner, @reflection.name)
          origin_find_target
        end
      end

      class BelongsToPolymorphicAssociation
        # call belongs_to association
        alias_method :origin_find_target, :find_target

        def find_target
          Bullet::Association.call_association(@owner, @reflection.name)
          origin_find_target
        end
      end
    end
  end
end
