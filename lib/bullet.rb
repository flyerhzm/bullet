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
        
        klazz.class_eval <<-END
          Bullet::Association.klazz_association(self).each do |association|
            origin_method_name = 'origin_' << association.to_s
            new_method_name = association.to_s
            alias_method origin_method_name, new_method_name
            
            define_method(association.to_s) do
              Bullet::Association.call_association(self, association)
              self.send(origin_method_name)
            end
          end
        END
        
        # class <<klazz
        #   alias_method :origin_find_every, :find_every
        # 
        #   def find_every(options)
        #     puts "find every #{options}"
        #     records = origin_find_every(options)
        #     include_associations = merge_includes(scope(:find, :include), options[:include])
        #     if !include_associations.any? and Bullet::Association.has_klazz_association(records.first.class)
        #       records.each do |record|
        #         Bullet::Association.check_association(record)
        #       end
        #     end
        #     records
        #   end
        # end
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
end

ActiveRecord::ActiveRecordError # An ActiveRecord bug

module ActiveRecord
  module Associations
    module ClassMethods
      alias_method :origin_collection_reader_method, :collection_reader_method
      
      def collection_reader_method(reflection, association_proxy_class)
        origin_collection_reader_method(reflection, association_proxy_class)
        Bullet::Association.define_association(self, reflection.name)
      end
    end
  end
end