module Bullet
  module Presenter
    class RailsLogger < Base
      def self.active?
        Bullet.rails_logger
      end

      def self.out_of_channel( notice )
        return unless active?
        Rails.logger.warn ''
        Rails.logger.warn notice.full_notice
      end
    end
  end
end
