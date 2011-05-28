module Bullet
  module Detector
    class Base
      def self.start_request
      end

      def self.end_request
        clear
      end
    end
  end
end
