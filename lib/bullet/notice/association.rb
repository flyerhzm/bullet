module Bullet
  module Notice
    class Association < Base
      def klazz_associations_str
        "  #{@base_class} => [#{@associations.map(&:inspect).join(', ')}]"
      end

      def associations_str
        ":include => #{@associations.map{|a| a.to_sym unless a.is_a? Hash}.inspect}"
      end
    end
  end
end
