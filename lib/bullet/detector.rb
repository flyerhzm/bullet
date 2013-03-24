module Bullet
  module Detector
    autoload :Base, 'bullet/detector/base'
    autoload :Association, 'bullet/detector/association'
    autoload :NPlusOneQuery, 'bullet/detector/n_plus_one_query'
    autoload :UnusedEagerAssociation, 'bullet/detector/unused_eager_association'
    autoload :CounterCache, 'bullet/detector/counter_cache'
  end
end
