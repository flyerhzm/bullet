module Bullet
  module Registry
    class Object < Base
      def add(bullet_ar_key)
        super(bullet_ar_key.bullet_class_name, bullet_ar_key)
      end

      def include?(bullet_ar_key)
        super(bullet_ar_key.bullet_class_name, bullet_ar_key)
      end
    end
  end
end
