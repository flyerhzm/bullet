module Bullet
  module Mongoid
    def self.enable
      require 'mongoid'

      ::Mongoid::Contexts::Mongo.class_eval do
        alias_method :origin_first, :first
        alias_method :origin_last, :last
        alias_method :origin_iterate, :iterate
        alias_method :origin_eager_load, :eager_load

        def first
          result = origin_first
          Bullet::Detector::NPlusOneQuery.add_impossible_object(result) if result
          result
        end

        def last
          result = origin_last
          Bullet::Detector::NPlusOneQuery.add_impossible_object(result) if result
          result
        end

        def iterate(&block)
          records = execute.to_a
          if records.size > 1
            Bullet::Detector::NPlusOneQuery.add_possible_objects(records)
          elsif records.size == 1
            Bullet::Detector::NPlusOneQuery.add_impossible_object(records.first)
          end
          origin_iterate(&block)
        end

        def eager_load(docs)
          associations = criteria.inclusions.map(&:name)
          docs.each do |doc|
            Bullet::Detector::Association.add_object_associations(doc, associations)
          end
          Bullet::Detector::UnusedEagerLoading.add_eager_loadings(docs, associations)
          origin_eager_load(docs)
        end
      end

      ::Mongoid::Relations::Accessors.class_eval do
        alias_method :origin_set_relation, :set_relation

        def set_relation(name, relation)
          if relation && relation.metadata.macro !~ /embed/
            Bullet::Detector::NPlusOneQuery.call_association(self, name)
          end
          origin_set_relation(name, relation)
        end
      end
    end
  end
end
