module Bullet
  module Detector
    class Base
      def self.start_request
      end

      def self.end_request
        clear
      end

      protected
      def self.unique( array )
        array.flatten!
        array.uniq!
      end

    end
  end
end
