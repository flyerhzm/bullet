module Bullet
  module Registry
    class Object < Base
      def add(object_ar_keys)
        klazz = Array(object_ar_keys).first.split(":").first
        super(klazz, object_ar_keys)
      end

      def include?(object_ar_key)
        klazz = object_ar_key.split(":").first
        super(klazz, object_ar_key)
      end
    end
  end
end
