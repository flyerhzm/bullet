module Bullet
  module Presenter
    class BulletLogger < Base
      def self.active? 
        Bullet.bullet_logger
      end

      def self.out_of_channel( notice )
        return unless active?
        Bullet.logger.info notice.full_notice
        Bullet.logger_file.flush
      end
    end
  end
end
