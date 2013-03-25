module Bullet
  module Notification
    class CounterCache < Base
      def body
        klazz_associations_str
      end

      def title
        "Need Counter Cache"
      end

      def caller_list; '' end
      
    end
  end
end
