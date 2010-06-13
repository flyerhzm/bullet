module Bullet
  module Notice
    autoload :Base, 'bullet/notice/base'
    autoload :UnusedEagerLoading, 'bullet/notice/unused_eager_loading'
    autoload :NPlusOneQuery, 'bullet/notice/n_plus_one_query'
    autoload :CounterCache, 'bullet/notice/counter_cache'
  end
end
