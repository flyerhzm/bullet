module Bullet
  module Presenter
    module BulletLogger
      def self.out_of_channel( notice )
        return unless Bullet.bullet_logger
        notice.log_messages.each { |msg| Bullet.logger.info msg }
        Bullet.logger_file.flush
      end
    end
  end
end
