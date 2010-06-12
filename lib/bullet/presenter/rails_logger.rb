module Bullet
  module Presenter
    module RailsLogger
      def self.out_of_channel( notice )
        return unless Bullet.rails_logger
        Rails.logger.warn ''
        notice.log_messages.each { |msg| Rails.logger.warn msg }
      end
    end
  end
end
