module Bullet
  module Mongoid
    def self.enable
      require 'mongoid'
      context = ::Mongoid::VERSION.split('.').first.to_i < 3 ? ::Mongoid::Contexts : ::Mongoid::Contextual
      context::Mongo.class_eval do
        alias_method :origin_first, :first
        alias_method :origin_last, :last
        alias_method :origin_iterate, :iterate

        def first
          result = origin_first
          Bullet::Detector::Association.add_impossible_object(result)
          result
        end

        def last
          result = origin_last
          Bullet::Detector::Association.add_impossible_object(result)
          result
        end

        def iterate(&block)
          records = execute.to_a
          if records.size > 1
            Bullet::Detector::Association.add_possible_objects(records)
          elsif records.size == 1
            Bullet::Detector::Association.add_impossible_object(records.first)
          end
          origin_iterate(&block)
        end
      end

      ::Mongoid::Relations::Accessors.class_eval do
        alias_method :origin_set_relation, :set_relation

        def set_relation(name, relation)
          Bullet::Detector::NPlusOneQuery.call_association(self, name)
          origin_set_relation(name, relation)
        end
      end

      context::Mongo.class_eval do
        alias_method :origin_eager_load, :eager_load

        def eager_load(docs)
          associations = criteria.inclusions.map(&:name)
          docs.each do |doc|
            Bullet::Detector::Association.add_object_associations(doc, associations)
          end
          Bullet::Detector::Association.add_eager_loadings(docs, associations)
          origin_eager_load(docs)
        end
      end
    end
  end
end
