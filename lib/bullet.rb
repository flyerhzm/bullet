module Bullet
  class Association
    class <<self
      def start_request
        @@associations = {}
      end

      def add_association(object, associations)
        @@associations[object] = associations
      end

      def call_association(object, associations)
      end

      def end_request
      end
    end
  end
end

module ActiveRecord
  module AssociationPreload
    module ClassMethods
      def preload_associations(records, associations, preload_options={})
        records = [records].flatten.compact.uniq
        return if records.empty?
        records.each do |record|
          puts "add association"
          Bullet::Association.add_association(record, associations)
        end
        case associations
        when Array then associations.each {|association| preload_associations(records, association, preload_options)}
        when Symbol, String then preload_one_association(records, associations.to_sym, preload_options)
        when Hash then
          associations.each do |parent, child|
            raise "parent must be an association name" unless parent.is_a?(String) || parent.is_a?(Symbol)
            preload_associations(records, parent, preload_options)
            reflection = reflections[parent]
            parents = records.map {|record| record.send(reflection.name)}.flatten.compact
            unless parents.empty?
              parents.first.class.preload_associations(parents, child)
            end
          end
        end
      end
    end
  end
end

module ActiveRecord
  module Associations
    module ClassMethods
      def collection_reader_method(reflection, association_proxy_class)
        define_method(reflection.name) do |*params|
          puts "call association"
          Bullet::Association.call_association(self, reflection.name)
          force_reload = params.first unless params.empty?
          association = association_instance_get(reflection.name)

          unless association
            association = association_proxy_class.new(self, reflection)
            association_instance_set(reflection.name, association)
          end

          association.reload if force_reload

          association
        end

        define_method("#{reflection.name.to_s.singularize}_ids") do
          if send(reflection.name).loaded? || reflection.options[:finder_sql]
            send(reflection.name).map(&:id)
          else
            send(reflection.name).all(:select => "#{reflection.quoted_table_name}.#{reflection.klass.primary_key}").map(&:id)
          end
        end
      end
    end
  end
end
