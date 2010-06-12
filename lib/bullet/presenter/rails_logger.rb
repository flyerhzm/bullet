module Bullet
  module Presenter
    class RailsLogger < Base
      def self.active?
        Bullet.rails_logger
      end

      def self.out_of_channel( notice )
        return unless active?
        Rails.logger.warn ''
        notice.log_messages.each { |msg| Rails.logger.warn msg }
      end
    end
  end
end
