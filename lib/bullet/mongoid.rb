module Bullet
  module Mongoid
    def self.enable
      require 'mongoid'
      ::Mongoid::Contexts::Mongo.class_eval do
        alias_method :origin_iterate, :iterate

        def iterate(&block)
          records = execute.to_a
          Bullet::Detector::Association.add_possible_objects(records)
          origin_iterate(&block)
        end
      end

      ::Mongoid::Relations::Accessors.class_eval do
        alias_method :origin_set_relation, :set_relation

        def set_relation(name, relation)
          Bullet::Detector::NPlusOneQuery.call_association(self, name)
          Bullet::Detector::Association.add_possible_objects(relation)
          origin_set_relation(name, relation)
        end
      end

      ::Mongoid::Contexts::Mongo.class_eval do
        alias_method :origin_eager_load, :eager_load

        def eager_load(docs)
          associations = criteria.inclusions.map(&:name)
          docs.each do |doc|
            Bullet::Detector::Association.add_object_associations(doc, associations)
            Bullet::Detector::NPlusOneQuery.call_association(doc, associations)
          end
          Bullet::Detector::Association.add_eager_loadings(docs, associations)
          origin_eager_load(docs)
        end
      end
    end
  end
end
