module Bullet
  module Presenter
    module RailsLogger
      def self.present( notice )
        return unless Bullet.rails_logger
        Rails.logger.warn ''
        notice.log_messages.each { |msg| Rails.logger.warn msg }
      end
    end
  end
end
