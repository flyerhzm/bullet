module Bullet
  module Presenter
    class BulletLogger < Base
      def self.active? 
        Bullet.bullet_logger
      end

      def self.out_of_channel( notice )
        return unless active?
        notice.log_messages.each { |msg| Bullet.logger.info msg }
        Bullet.logger_file.flush
      end
    end
  end
end
