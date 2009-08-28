module Bullet
  module ActiveRecord
    def self.enable
      ::ActiveRecord::Base.class_eval do
        class << self
          alias_method :bullet_find_every, :find_every
          # if select a collection of objects, then these objects have possible to cause N+1 query
          # if select only one object, then the only one object has impossible to cause N+1 query
          def find_every(options)
            records = bullet_find_every(options)

            if records 
              if records.size > 1
                Bullet::Association.add_possible_objects(records)
              elsif records.size == 1
                Bullet::Association.add_impossible_object(records.first)
              end
            end

            records
          end

          alias_method :bullet_preload_associations, :preload_associations
          # add include for one to many associations query
          def preload_associations(records, associations, preload_options={})
            records = [records].flatten.compact.uniq
            return if records.empty?
            records.each do |record|
              Bullet::Association.add_association(record, associations)
            end
            bullet_preload_associations(records, associations, preload_options={})
          end

          # define one to many associations
          alias_method :bullet_collection_reader_method, :collection_reader_method
          def collection_reader_method(reflection, association_proxy_class)
            Bullet::Association.define_association(self, reflection.name)
            bullet_collection_reader_method(reflection, association_proxy_class)
          end
        end
      end

      ::ActiveRecord::Associations::AssociationCollection.class_eval do
        # call one to many associations
        alias_method :bullet_load_target, :load_target
        def load_target
          Bullet::Association.call_association(@owner, @reflection.name)
          bullet_load_target
        end  
      end
      
      ::ActiveRecord::Associations::AssociationProxy.class_eval do
        # call has_one association
        alias_method :bullet_load_target, :load_target
        def load_target
          Bullet::Association.call_association(@owner, @reflection.name)
          bullet_load_target
        end
      end
    end
  end
end