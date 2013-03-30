module Bullet
  module ActiveRecord
    def self.enable
      require 'active_record'
      ::ActiveRecord::Relation.class_eval do
        alias_method :origin_to_a, :to_a
        # if select a collection of objects, then these objects have possible to cause N+1 query.
        # if select only one object, then the only one object has impossible to cause N+1 query.
        def to_a
          records = origin_to_a
          if records.size > 1
            Bullet::Detector::NPlusOneQuery.add_possible_objects(records)
            Bullet::Detector::CounterCache.add_possible_objects(records)
          elsif records.size == 1
            Bullet::Detector::NPlusOneQuery.add_impossible_object(records.first)
            Bullet::Detector::CounterCache.add_impossible_object(records.first)
          end
          records
        end
      end

      ::ActiveRecord::AssociationPreload::ClassMethods.class_eval do
        alias_method :origin_preload_associations, :preload_associations
        # include query for one to many associations.
        # keep this eager loadings.
        def preload_associations(records, associations, preload_options={})
          records = [records].flatten.compact.uniq
          return if records.empty?
          records.each do |record|
            Bullet::Detector::Association.add_object_associations(record, associations)
          end
          Bullet::Detector::UnusedEagerLoading.add_eager_loadings(records, associations)
          origin_preload_associations(records, associations, preload_options={})
        end
      end

      ::ActiveRecord::FinderMethods.class_eval do
        # add includes in scope
        alias_method :origin_find_with_associations, :find_with_associations
        def find_with_associations
          records = origin_find_with_associations
          associations = (@eager_load_values + @includes_values).uniq
          records.each do |record|
            Bullet::Detector::Association.add_object_associations(record, associations)
            Bullet::Detector::NPlusOneQuery.call_association(record, associations)
          end
          Bullet::Detector::UnusedEagerLoading.add_eager_loadings(records, associations)
          records
        end
      end

      ::ActiveRecord::Associations::ClassMethods::JoinDependency.class_eval do
        alias_method :origin_construct_association, :construct_association
        # call join associations
        def construct_association(record, join, row)
          associations = join.reflection.name
          Bullet::Detector::Association.add_object_associations(record, associations)
          Bullet::Detector::NPlusOneQuery.call_association(record, associations)
          origin_construct_association(record, join, row)
        end
      end

    ::ActiveRecord::Associations::AssociationCollection.class_eval do
        # call one to many associations
        alias_method :origin_load_target, :load_target
        def load_target
          Bullet::Detector::NPlusOneQuery.call_association(@owner, @reflection.name)
          origin_load_target
        end

        alias_method :origin_first, :first
        def first(*args)
          Bullet::Detector::NPlusOneQuery.call_association(@owner, @reflection.name)
          origin_first(*args)
        end

        alias_method :origin_last, :last
        def last(*args)
          Bullet::Detector::NPlusOneQuery.call_association(@owner, @reflection.name)
          origin_last(*args)
        end
      end

      ::ActiveRecord::Associations::AssociationProxy.class_eval do
        # call has_one and belong_to association
        alias_method :origin_load_target, :load_target
        def load_target
          # avoid stack level too deep
          result = origin_load_target
          Bullet::Detector::NPlusOneQuery.call_association(@owner, @reflection.name) unless caller.any? { |c| c.include?("load_target") }
          Bullet::Detector::NPlusOneQuery.add_possible_objects(result)
          result
        end

        alias_method :origin_set_inverse_instance, :set_inverse_instance
        def set_inverse_instance(record, instance)
          if record && we_can_set_the_inverse_on_this?(record)
            Bullet::Detector::NPlusOneQuery.add_impossible_object(record)
          end
          origin_set_inverse_instance(record, instance)
        end
      end

      ::ActiveRecord::Associations::HasManyAssociation.class_eval do
        alias_method :origin_has_cached_counter?, :has_cached_counter?

        def has_cached_counter?
          result = origin_has_cached_counter?
          Bullet::Detector::CounterCache.add_counter_cache(@owner, @reflection.name) unless result
          result
        end
      end

      ::ActiveRecord::Associations::HasManyThroughAssociation.class_eval do
        alias_method :origin_has_cached_counter?, :has_cached_counter?
        def has_cached_counter?
          result = origin_has_cached_counter?
          Bullet::Detector::CounterCache.add_counter_cache(@owner, @reflection.name) unless result
          result
        end
      end
    end
  end
end
