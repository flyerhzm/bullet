module Bullet
  module Presenter
    module BulletLogger
      def present( notice )
        notice.log_messages.each { |msg| Bullet.logger.info msg }
        Bullet.logger_file.flush
      end
    end
  end
end
